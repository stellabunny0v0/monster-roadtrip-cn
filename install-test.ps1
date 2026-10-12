param(
    [string]$GameDir = $env:MONSTER_ROADTRIP_GAME_DIR
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$loaderRoot = Join-Path $projectRoot '.tools\bepinex-x86'
$modRoot = Join-Path $projectRoot 'build\package'

if ([string]::IsNullOrWhiteSpace($GameDir)) {
    throw 'Pass -GameDir or set MONSTER_ROADTRIP_GAME_DIR first.'
}

$gameExe = Join-Path $GameDir 'MonsterRoadtrip.exe'

if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) {
    throw "Game executable was not found: $gameExe"
}

& (Join-Path $projectRoot 'backup-saves.ps1') -GameDir $GameDir

$expectedExeHash = 'CEAA015A4723C16BC1763129BE98FE3A73A5D9EE44168DCA5076BB954FAFC7E9'
$actualExeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $gameExe).Hash
if ($actualExeHash -ne $expectedExeHash) {
    Write-Warning "Game executable differs from the version used for development: $actualExeHash"
}

$existingProxy = Join-Path $GameDir 'winhttp.dll'
$packagedProxy = Join-Path $loaderRoot 'winhttp.dll'
if (Test-Path -LiteralPath $existingProxy) {
    $existingHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $existingProxy).Hash
    $packagedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $packagedProxy).Hash
    if ($existingHash -ne $packagedHash) {
        throw 'A different winhttp.dll already exists in the game directory. Installation stopped.'
    }
}

$gameCoreDir = Join-Path $GameDir 'BepInEx\core'
$gamePluginDir = Join-Path $GameDir 'BepInEx\plugins\MonsterRoadtripChinese'
New-Item -ItemType Directory -Path $gameCoreDir,$gamePluginDir -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $loaderRoot '.doorstop_version'),(Join-Path $loaderRoot 'changelog.txt'),(Join-Path $loaderRoot 'doorstop_config.ini'),(Join-Path $loaderRoot 'winhttp.dll') -Destination $GameDir -Force
Copy-Item -Path (Join-Path $loaderRoot 'BepInEx\core\*') -Destination $gameCoreDir -Recurse -Force
Copy-Item -Path (Join-Path $modRoot 'BepInEx\plugins\MonsterRoadtripChinese\*') -Destination $gamePluginDir -Recurse -Force

Write-Host 'Test build installed.'
Write-Host "Launch the game normally through Steam, then inspect BepInEx\LogOutput.log."

