param([string]$GameDir = $env:MONSTER_ROADTRIP_GAME_DIR)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($GameDir)) { throw 'Pass -GameDir or set MONSTER_ROADTRIP_GAME_DIR.' }
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$probeRoots = @(
    (Join-Path $GameDir 'MonsterRoadtrip_Data\Managed'),
    (Join-Path $projectRoot '.tools\bepinex-x86\BepInEx\core'),
    (Join-Path $projectRoot 'src\bin\Release')
)
# Inspect IL only. No game objects, game startup or save methods are invoked.
$resolver = [ResolveEventHandler]{param($sender,$eventArgs)
    $simpleName = ([Reflection.AssemblyName]::new($eventArgs.Name)).Name
    foreach ($root in $probeRoots) {
        $candidate = Join-Path $root ($simpleName + '.dll')
        if (Test-Path -LiteralPath $candidate) { return [Reflection.Assembly]::LoadFrom($candidate) }
    }
    return $null
}
[AppDomain]::CurrentDomain.add_AssemblyResolve($resolver)
try {
    $harmonyAssembly = [Reflection.Assembly]::LoadFrom((Join-Path $probeRoots[1] '0Harmony.dll'))
    $gameAssembly = [Reflection.Assembly]::LoadFrom((Join-Path $probeRoots[0] 'Assembly-CSharp.dll'))
    $targetType = $gameAssembly.GetType('BeautifulGlitch.CoreCheckpointXmlSerializer', $true)
    $target = $targetType.GetMethod('SerializeCorePlayerData', [Reflection.BindingFlags]'Instance,NonPublic')
    # The Unity/Mono Harmony IL reader cannot inspect this assembly in every
    # desktop PowerShell runtime. Read metadata directly, without JIT or calls.
    $opcodes = @{}
    foreach ($field in [Reflection.Emit.OpCodes].GetFields([Reflection.BindingFlags]'Static,Public')) {
        $opcode = $field.GetValue($null)
        $opcodes[[int]$opcode.Value -band 0xffff] = $opcode
    }
    $bytes = $target.GetMethodBody().GetILAsByteArray()
    $instructions = [Collections.Generic.List[HarmonyLib.CodeInstruction]]::new()
    $position = 0
    while ($position -lt $bytes.Length) {
        $number = [int]$bytes[$position++]
        if ($number -eq 0xfe) { $number = 0xfe00 -bor $bytes[$position++] }
        $opcode = $opcodes[$number]
        if ($null -eq $opcode) { throw 'Unknown IL opcode.' }
        $operand = $null
        switch ($opcode.OperandType.ToString()) {
            'InlineNone' { }
            'ShortInlineI' { $operand = [int]$bytes[$position++] }
            'ShortInlineVar' { $operand = [int]$bytes[$position++] }
            'ShortInlineBrTarget' { $operand = [int]$bytes[$position++] }
            'InlineVar' { $operand = [BitConverter]::ToUInt16($bytes,$position); $position += 2 }
            'InlineI8' { $operand = [BitConverter]::ToInt64($bytes,$position); $position += 8 }
            'InlineR' { $operand = [BitConverter]::ToDouble($bytes,$position); $position += 8 }
            'ShortInlineR' { $operand = [BitConverter]::ToSingle($bytes,$position); $position += 4 }
            'InlineSwitch' {
                $count = [BitConverter]::ToInt32($bytes,$position); $position += 4
                $operand = [int[]]::new($count)
                for ($j = 0; $j -lt $count; $j++) { $operand[$j] = [BitConverter]::ToInt32($bytes,$position); $position += 4 }
            }
            default {
                $token = [BitConverter]::ToInt32($bytes,$position); $position += 4
                if ($opcode.OperandType.ToString() -eq 'InlineMethod') { $operand = $target.Module.ResolveMethod($token) }
                elseif ($opcode.OperandType.ToString() -eq 'InlineString') { $operand = $target.Module.ResolveString($token) }
                else { $operand = $token }
            }
        }
        $instructions.Add([HarmonyLib.CodeInstruction]::new($opcode,$operand))
    }
    if ($position -ne $bytes.Length) { throw 'Invalid IL stream length.' }
    $originalWriterCalls = @($instructions | Where-Object { $_.operand -is [Reflection.MethodInfo] -and $_.operand.Name -eq 'WriteElementString' }).Count
    if ($originalWriterCalls -lt 1) { throw 'Actual game serializer has no expected XML writer calls.' }
    $snapshot = @($instructions | ForEach-Object {
        [pscustomobject]@{ Opcode = $_.opcode; Operand = $_.operand }
    })
    $pluginAssembly = [Reflection.Assembly]::LoadFrom((Join-Path $probeRoots[2] 'MonsterRoadtripChinese.dll'))
    $patch = $pluginAssembly.GetType('MonsterRoadtripChinese.Plugin+PlayerNameWritePatch', $true)
    $transpiler = $patch.GetMethod('Transpiler', [Reflection.BindingFlags]'Static,NonPublic')
    $arguments = [object[]]::new(1)
    $arguments[0] = $instructions
    $after = @($transpiler.Invoke($null, $arguments))
    if ($after.Count -ne $snapshot.Count) { throw 'Instruction count changed unexpectedly.' }
    $changed = 0
    for ($i = 0; $i -lt $after.Count; $i++) {
        $before = $snapshot[$i]
        if ($before.Operand -is [Reflection.MethodInfo] -and $before.Operand.Name -eq 'WriteElementString') {
            if ($after[$i].opcode -ne [Reflection.Emit.OpCodes]::Call -or
                $after[$i].operand.DeclaringType.FullName -ne 'MonsterRoadtripChinese.NameTextPersistence') {
                throw 'Expected XML writer call was not redirected to the tested helper.'
            }
            $changed++
        } elseif ($after[$i].opcode -ne $before.Opcode -or $after[$i].operand -ne $before.Operand) {
            throw 'An unrelated game instruction changed.'
        }
    }
    if ($changed -ne $originalWriterCalls) { throw 'Incomplete name serialization hook.' }
    Write-Output "PASS: actual game serializer IL; $changed XML writer calls redirected, all other instructions unchanged; no save method executed"
} finally {
    [AppDomain]::CurrentDomain.remove_AssemblyResolve($resolver)
}
