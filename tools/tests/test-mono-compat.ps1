$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$helperPath = Join-Path $repoRoot 'build\mono-compat\MonsterRoadtripMonoCompat.dll'
[void][Reflection.Assembly]::LoadFrom($helperPath)
$cases = @(
    @(4,$false,$true,$false,79), @(4,$false,$true,$true,83),
    @(8,$false,$true,$false,115), @(8,$false,$true,$true,115),
    @(4,$false,$false,$false,75), @(8,$false,$false,$false,107),
    @(4,$true,$true,$false,87), @(4,$true,$true,$true,91),
    @(8,$true,$true,$false,123), @(8,$true,$true,$true,123)
)
foreach ($case in $cases) {
    $actual = [MonsterRoadtripMonoCompat.MonoCorlibLayout]::ComputeOffset($case[0],$case[1],$case[2],$case[3])
    if ($actual -ne $case[4]) {throw "Wrong Mono layout offset: $actual, expected $($case[4])"}
}
$rejected = $false
try { [MonsterRoadtripMonoCompat.MonoCorlibLayout]::ComputeOffset(16,$false,$true,$true) | Out-Null }
catch { $rejected = $_.Exception.InnerException -is [ArgumentOutOfRangeException] }
if (-not $rejected) {throw 'Unsupported pointer size was not rejected.'}

[void][Reflection.Assembly]::LoadFrom((Join-Path $repoRoot '.tools\bepinex-x86\BepInEx\core\Mono.Cecil.dll'))
$original = [Mono.Cecil.AssemblyDefinition]::ReadAssembly((Join-Path $repoRoot '.tools\bepinex-x86\BepInEx\core\MonoMod.Utils.dll'))
$patched = [Mono.Cecil.AssemblyDefinition]::ReadAssembly((Join-Path $repoRoot 'build\mono-compat\MonoMod.Utils.dll'))
function Get-Types($types) {
    foreach ($type in $types) {
        $type
        Get-Types $type.NestedTypes
    }
}
function Get-Body($method, [bool]$omitCorrection) {
    if (-not $method.HasBody) { return 'no-body' }
    $instructions = @($method.Body.Instructions | Where-Object {
        -not ($omitCorrection -and $_.OpCode.Code -eq 'Call' -and
            $_.Operand.FullName -eq 'System.Int32 MonsterRoadtripMonoCompat.MonoCorlibLayout::CorrectOffset(System.Int32)')
    })
    $indexes = [Collections.Generic.Dictionary[Mono.Cecil.Cil.Instruction,int]]::new()
    for ($i=0; $i -lt $instructions.Count; $i++) { $indexes.Add($instructions[$i],$i) }
    $rows = [Collections.Generic.List[string]]::new()
    $rows.Add('locals:' + (($method.Body.Variables | ForEach-Object {$_.VariableType.FullName}) -join ';'))
    $rows.Add('init-locals:' + $method.Body.InitLocals)
    foreach ($instruction in $instructions) {
        $operand = $instruction.Operand
        if ($operand -is [Mono.Cecil.Cil.Instruction]) { $value = 'target:' + $indexes[$operand] }
        elseif ($operand -is [Mono.Cecil.Cil.Instruction[]]) { $value = 'targets:' + (($operand | ForEach-Object {$indexes[$_]}) -join ',') }
        else { $value = [string]$operand }
        $rows.Add($instruction.OpCode.Code.ToString() + ' ' + $value)
    }
    foreach ($handler in $method.Body.ExceptionHandlers) {
        $parts = @($handler.HandlerType.ToString(),[string]$handler.CatchType)
        foreach ($boundary in @($handler.TryStart,$handler.TryEnd,$handler.HandlerStart,$handler.HandlerEnd,$handler.FilterStart)) {
            $parts += $(if ($null -eq $boundary) {'end'} else {[string]$indexes[$boundary]})
        }
        $rows.Add('handler:' + ($parts -join '|'))
    }
    return $rows -join "`n"
}
try {
    $before = @{}
    foreach ($type in (Get-Types $original.MainModule.Types)) {
        foreach ($method in $type.Methods) {
            $key = $method.FullName + '|generic-arity:' + $method.GenericParameters.Count
            if ($before.ContainsKey($key)) {throw 'Ambiguous method comparison key.'}
            $before[$key] = Get-Body $method $false
        }
    }
    $count = 0
    $corrections = 0
    foreach ($type in (Get-Types $patched.MainModule.Types)) {
        foreach ($method in $type.Methods) {
            $count++
            $key = $method.FullName + '|generic-arity:' + $method.GenericParameters.Count
            if (-not $before.ContainsKey($key)) { throw 'Unexpected added method.' }
            if ($before[$key] -cne (Get-Body $method $true)) { throw "Unexpected IL change: $($method.FullName)" }
            if ($method.HasBody) {
                $calls = @($method.Body.Instructions | Where-Object {
                    $_.OpCode.Code -eq 'Call' -and $_.Operand.FullName -eq 'System.Int32 MonsterRoadtripMonoCompat.MonoCorlibLayout::CorrectOffset(System.Int32)'
                })
                if ($calls.Count -gt 0 -and $method.Name -ne 'SetMonoCorlibInternal') {throw 'Correction inserted into another method.'}
                $corrections += $calls.Count
            }
        }
    }
    if ($count -ne $before.Count -or $corrections -ne 1) {throw 'Unexpected method/instruction counts.'}
    $refsBefore = @($original.MainModule.AssemblyReferences | ForEach-Object FullName)
    $refsAfter = @($patched.MainModule.AssemblyReferences | ForEach-Object FullName)
    $extra = @($refsAfter | Where-Object {$_ -notin $refsBefore})
    if ($extra.Count -ne 1 -or $extra[0] -notlike 'MonsterRoadtripMonoCompat,*') {throw 'Unexpected assembly reference change.'}
    if (@($refsBefore | Where-Object {$_ -notin $refsAfter}).Count -ne 0) {throw 'Original reference removed.'}
    "PASS: 10 layout cases, invalid size rejected, all $count method bodies preserved except one offset correction call."
}
finally { $original.Dispose(); $patched.Dispose() }
