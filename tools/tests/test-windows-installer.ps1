param(
    [Parameter(Mandatory=$true)][string]$PackageDirectory,
    [Parameter(Mandatory=$true)][string]$SourceGameDirectory,
    [Parameter(Mandatory=$true)][string]$TestRoot
)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$package=[IO.Path]::GetFullPath($PackageDirectory)
$root=[IO.Path]::GetFullPath($TestRoot).TrimEnd('\')
if ($root -match '[^\x00-\x7F]' -or $root -notlike '*\monster-roadtrip-installer-tests-*') {throw 'Use a dedicated ASCII temporary test directory.'}
if (Test-Path -LiteralPath $root) {throw 'Test directory already exists; no files removed.'}
New-Item -ItemType Directory -Path $root | Out-Null
Set-Content -LiteralPath (Join-Path $root 'owned-test-marker.txt') -Value 'MonsterRoadtripChinese installer integration tests'
$manifest=Get-Content -LiteralPath (Join-Path $package 'package-manifest.json') -Raw | ConvertFrom-Json
$ps='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$results=[Collections.Generic.List[string]]::new()
function Hash([string]$path) {return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
function Make-Game([string]$name) {
    $path=Join-Path $root $name
    New-Item -ItemType Directory -Path $path | Out-Null
    foreach($item in $manifest.gameFiles) {
        $dest=Join-Path $path $item.path
        New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $SourceGameDirectory $item.path) -Destination $dest
    }
    New-Item -ItemType Directory -Path (Join-Path $path 'UserData') | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $path 'UserData\save-sentinel.xml'),[byte[]]@(0,1,2,3,128,255,60,62))
    Set-Content -LiteralPath (Join-Path $path 'unrelated-user-file.txt') -Value 'Do not change this file'
    return $path
}
function Run-Manager([string]$game,[string]$mode,[int]$expected,[string]$label,[switch]$CheckOnly,[string]$PackageOverride='') {
    $targetPackage=if($PackageOverride){$PackageOverride}else{$package}
    $arguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $targetPackage 'installer\Manage-Mod.ps1'),'-Mode',$mode,'-GameDir',$game,'-BackupRoot',(Join-Path $root 'backups'),'-NonInteractive')
    if($CheckOnly){$arguments+='-ValidateOnly'}
    & $ps @arguments *> (Join-Path $root ($label+'.log'))
    if($LASTEXITCODE -ne $expected){Get-Content -LiteralPath (Join-Path $root ($label+'.log'));throw "Unexpected exit for ${label}: $LASTEXITCODE, expected $expected"}
    $results.Add($label)
}
function Assert-Safe([string]$game,[string]$saveHash,[string]$userHash) {
    if((Hash (Join-Path $game 'UserData\save-sentinel.xml')) -ne $saveHash){throw 'Save was modified'}
    if((Hash (Join-Path $game 'unrelated-user-file.txt')) -ne $userHash){throw 'Unrelated file was modified'}
    foreach($item in $manifest.gameFiles){if((Hash (Join-Path $game $item.path)) -ne $item.sha256){throw 'Original game binary was modified'}}
}

$clean=Make-Game 'clean-game'
$saveHash=Hash (Join-Path $clean 'UserData\save-sentinel.xml')
$userHash=Hash (Join-Path $clean 'unrelated-user-file.txt')
Run-Manager $clean Install 0 'preflight-is-read-only' -CheckOnly
if(Test-Path -LiteralPath (Join-Path $clean 'BepInEx')){throw 'Preflight created game files'}

[IO.File]::WriteAllText((Join-Path $clean 'winhttp.dll'),'another loader')
Run-Manager $clean Install 1 'reject-unknown-loader' -CheckOnly
if([IO.File]::ReadAllText((Join-Path $clean 'winhttp.dll')) -ne 'another loader'){throw 'Other loader overwritten'}
Remove-Item -LiteralPath (Join-Path $clean 'winhttp.dll')

$tampered=Join-Path $root 'tampered-package'
Copy-Item -LiteralPath $package -Destination $tampered -Recurse
$pluginItem=$manifest.files | Where-Object {$_.path -eq 'BepInEx/plugins/MonsterRoadtripChinese/MonsterRoadtripChinese.dll'}
$tamperedPlugin=Join-Path (Join-Path $tampered 'payload') $pluginItem.path
[IO.File]::AppendAllText($tamperedPlugin,'corrupt')
Run-Manager $clean Install 1 'reject-corrupt-package' -CheckOnly -PackageOverride $tampered
if(Test-Path -LiteralPath (Join-Path $clean 'BepInEx')){throw 'Corrupt package installed files'}
Copy-Item -LiteralPath (Join-Path (Join-Path $package 'payload') $pluginItem.path) -Destination $tamperedPlugin -Force
$badManifest=Get-Content -LiteralPath (Join-Path $tampered 'package-manifest.json') -Raw | ConvertFrom-Json
$badManifest.files[0].path='../outside.txt'
$badManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $tampered 'package-manifest.json') -Encoding UTF8
Run-Manager $clean Install 1 'reject-escaping-path' -CheckOnly -PackageOverride $tampered

$exe=Join-Path $clean 'MonsterRoadtrip.exe'
[IO.File]::AppendAllText($exe,'unsupported update')
Run-Manager $clean Install 1 'reject-untested-game-version' -CheckOnly
Copy-Item -LiteralPath (Join-Path $SourceGameDirectory 'MonsterRoadtrip.exe') -Destination $exe -Force

Run-Manager $clean Install 0 'clean-install'
$statePath=Join-Path $clean 'BepInEx\MonsterRoadtripChinese.install.json'
$state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
foreach($item in $manifest.files){if((Hash (Join-Path $clean $item.path)) -ne $item.sha256){throw 'Installed payload mismatch'}}
if((Hash (Join-Path $state.backupDirectory 'UserData\save-sentinel.xml')) -ne $saveHash){throw 'Save backup mismatch'}
Run-Manager $clean Install 0 'repeat-install-is-idempotent'
Run-Manager $clean Uninstall 0 'uninstall-preflight' -CheckOnly
Run-Manager $clean Uninstall 0 'clean-uninstall'
if((Test-Path -LiteralPath (Join-Path $clean 'winhttp.dll')) -or (Test-Path -LiteralPath (Join-Path $clean $pluginItem.path))){throw 'Owned active loader/plugin left behind'}
Assert-Safe $clean $saveHash $userHash

$shared=Make-Game 'existing-loader-game'
foreach($item in $manifest.files | Where-Object {$_.kind -eq 'loader'}){
    $source=Join-Path (Join-Path $package 'payload') $item.path
    $dest=Join-Path $shared $item.path
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $dest
}
# Start with the original, known loader dependency; the installer must back it up.
Copy-Item -LiteralPath (Join-Path $repoRoot '.tools\bepinex-x86\BepInEx\core\MonoMod.Utils.dll') -Destination (Join-Path $shared 'BepInEx\core\MonoMod.Utils.dll') -Force
$cfgDir=Join-Path $shared 'BepInEx\config'
New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
$config=Join-Path $cfgDir 'cn.monsterroadtrip.localization.cfg'
Set-Content -LiteralPath $config -Value '[NameRecovery] retained local preference'
$configHash=Hash $config
$door=Join-Path $shared 'doorstop_config.ini'
[IO.File]::AppendAllText($door,"`r`n# Existing custom configuration`r`n")
$doorHash=Hash $door
$other=Join-Path $shared 'BepInEx\plugins\OtherMod\OtherMod.dll'
New-Item -ItemType Directory -Path (Split-Path -Parent $other) -Force | Out-Null
Set-Content -LiteralPath $other -Value 'Other mod sentinel, never executed'
$otherHash=Hash $other
Run-Manager $shared Install 0 'existing-loader-preserves-config-and-other-mod'
if((Hash $config) -ne $configHash -or (Hash $door) -ne $doorHash -or (Hash $other) -ne $otherHash){throw 'Existing configuration/mod changed'}
$changed=Join-Path $shared $pluginItem.path
[IO.File]::AppendAllText($changed,'user edit')
Run-Manager $shared Uninstall 1 'refuse-to-delete-user-modified-plugin'
if(-not(Test-Path -LiteralPath $changed)){throw 'Modified plugin deleted'}
Copy-Item -LiteralPath (Join-Path (Join-Path $package 'payload') $pluginItem.path) -Destination $changed -Force
Run-Manager $shared Uninstall 0 'shared-loader-uninstall-preserves-other-mod'
if((Hash $other) -ne $otherHash -or (Hash $config) -ne $configHash -or (Hash $door) -ne $doorHash){throw 'Other mod/config lost during uninstall'}
if(-not(Test-Path -LiteralPath (Join-Path $shared 'BepInEx\core\BepInEx.dll'))){throw 'Shared loader removed'}
if(Test-Path -LiteralPath $changed){throw 'Chinese plugin still active'}
Assert-Safe $shared $saveHash $userHash
$report=[ordered]@{powershell='Windows PowerShell 5.1';cases=$results.Count;passed=@($results);savesUnchanged=$true;gameBinariesUnchanged=$true;otherModAndConfigPreserved=$true;testRoot=$root}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root 'test-report.json') -Encoding UTF8
$report | ConvertTo-Json -Depth 5
