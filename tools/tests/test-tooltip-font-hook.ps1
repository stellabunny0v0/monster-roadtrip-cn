param([string]$GameDir = $env:MONSTER_ROADTRIP_GAME_DIR)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($GameDir)) { throw 'Pass -GameDir or set MONSTER_ROADTRIP_GAME_DIR.' }
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
[void][Reflection.Assembly]::LoadFrom((Join-Path $repoRoot '.tools\bepinex-x86\BepInEx\core\Mono.Cecil.dll'))
$game = [Mono.Cecil.AssemblyDefinition]::ReadAssembly((Join-Path $GameDir 'MonsterRoadtrip_Data\Managed\Assembly-CSharp.dll'))
$plugin = [Mono.Cecil.AssemblyDefinition]::ReadAssembly((Join-Path $repoRoot 'src\bin\Release\MonsterRoadtripChinese.dll'))
try {
    # Metadata inspection only: no Unity objects, game startup, buff or save calls.
    $tooltip = $game.MainModule.Types | Where-Object FullName -eq 'Game.StatsBoxItemTooltip'
    $original = $tooltip.Methods | Where-Object Name -eq 'Show'
    if (-not $original -or -not $original.HasBody) { throw 'Missing real tooltip Show method.' }
    $originalCalls = @($original.Body.Instructions | Where-Object {$_.Operand -is [Mono.Cecil.MethodReference]} | ForEach-Object {$_.Operand.FullName})
    if (-not ($originalCalls | Where-Object {$_ -match 'CoreTextManager::GetText|TextManager::GetText'}) -or
        -not ($originalCalls | Where-Object {$_ -match 'UILabel::set_text'})) { throw 'Game tooltip no longer uses the expected text lookup and label.' }
    $type = $plugin.MainModule.Types | Where-Object FullName -eq 'MonsterRoadtripChinese.Plugin'
    $patch = $type.NestedTypes | Where-Object Name -eq 'StatsBoxItemTooltipFontPatch'
    if (-not $patch -or $patch.Methods.Count -ne 2) { throw 'Expected only target selection and a prefix.' }
    $prefix = $patch.Methods | Where-Object Name -eq 'Prefix'
    if ($prefix.ReturnType.FullName -ne 'System.Void' -or $prefix.Parameters.Count -ne 1 -or
        $prefix.Parameters[0].ParameterType.FullName -ne 'Game.StatsBoxItemTooltip') { throw 'Font prefix must not suppress or replace the game Show method.' }
    $calls = @($prefix.Body.Instructions | Where-Object {$_.Operand -is [Mono.Cecil.MethodReference]} | ForEach-Object {$_.Operand.FullName})
    if (-not ($calls | Where-Object {$_ -match 'UILabel::set_trueTypeFont'}) -or
        -not ($prefix.Body.Instructions | Where-Object {$_.OpCode.Name -eq 'stfld' -and $_.Operand.FullName -match 'UILabel::keepCrispWhenShrunk'})) { throw 'Tooltip font refresh is missing.' }
    foreach ($call in $calls) {
        if ($call -notmatch 'UnityEngine.Object::op_Equality|UILabel::set_trueTypeFont') { throw "Non-display call in tooltip prefix: $call" }
    }
    if ($prefix.Body.Instructions | Where-Object {$_.OpCode.Name -match '^st(fld|sfld)$' -and $_.Operand.FullName -notmatch 'UILabel::keepCrispWhenShrunk'}) { throw 'Unexpected field write in tooltip prefix.' }
    $fields = @($prefix.Body.Instructions | Where-Object {$_.Operand -is [Mono.Cecil.FieldReference]} | ForEach-Object {$_.Operand.FullName} | Select-Object -Unique)
    foreach ($field in $fields) {
        if ($field -notmatch 'Plugin::ChineseFont|StatsBoxItemTooltip::uiLabel|UILabel::keepCrispWhenShrunk') { throw "Unexpected field access: $field" }
    }
    $target = $patch.Methods | Where-Object Name -eq 'TargetMethod'
    if (-not ($target.Body.Instructions | Where-Object {$_.Operand -is [Mono.Cecil.TypeReference] -and $_.Operand.FullName -eq 'Game.StatsBoxItemTooltip'}) -or
        -not ($target.Body.Instructions | Where-Object {$_.OpCode.Name -eq 'ldstr' -and $_.Operand -eq 'Show'})) { throw 'Wrong tooltip target.' }
    $awake = $type.Methods | Where-Object Name -eq 'Awake'
    if (-not ($awake.Body.Instructions | Where-Object {$_.Operand -is [Mono.Cecil.TypeReference] -and $_.Operand.Name -eq $patch.Name})) { throw 'Tooltip patch is not registered.' }
    $label = $game.MainModule.Types | Where-Object FullName -eq 'UILabel'
    $setter = $label.Methods | Where-Object Name -eq 'set_trueTypeFont'
    $setterCalls = @($setter.Body.Instructions | Where-Object {$_.Operand -is [Mono.Cecil.MethodReference]} | ForEach-Object {$_.Operand.Name})
    if ('ProcessAndRequest' -notin $setterCalls -or 'SetActiveFont' -notin $setterCalls -or 'RemoveFromPanel' -notin $setterCalls) { throw 'Font setter no longer refreshes cached label geometry.' }
    Write-Output 'PASS: actual tooltip target/registration; void prefix only changes label font; property setter refreshes cached geometry; no buff, stat or save calls executed'
} finally {
    $game.Dispose()
    $plugin.Dispose()
}
