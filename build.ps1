param(
    [string]$GameDir = $env:MONSTER_ROADTRIP_GAME_DIR
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:PYTHONPATH = Join-Path $projectRoot '.tools\python'
$env:DOTNET_CLI_HOME = $projectRoot
$env:APPDATA = Join-Path $projectRoot '.appdata'
$env:NUGET_PACKAGES = Join-Path $projectRoot '.tools\nuget-packages'
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

if ([string]::IsNullOrWhiteSpace($GameDir)) {
    throw 'Pass -GameDir or set MONSTER_ROADTRIP_GAME_DIR first.'
}

Push-Location $projectRoot
try {
    python tools\sanitize_machine_translation.py
    if ($LASTEXITCODE -ne 0) { throw 'Machine translation sanitation failed.' }

    python tools\apply_overrides.py
    if ($LASTEXITCODE -ne 0) { throw 'Human translation overrides failed.' }

    python tools\validate_translation.py
    if ($LASTEXITCODE -ne 0) { throw 'Translation validation failed.' }

    python tools\build_translation.py
    if ($LASTEXITCODE -ne 0) { throw 'Translation build failed.' }

    python tools\validate_runtime_contracts.py
    if ($LASTEXITCODE -ne 0) { throw 'Runtime contract validation failed.' }

    dotnet build src\MonsterRoadtripChinese.csproj --configuration Release --no-restore -p:GameDir="$GameDir"
    if ($LASTEXITCODE -ne 0) { throw 'Plugin build failed.' }

    $pluginDir = Join-Path $projectRoot 'build\package\BepInEx\plugins\MonsterRoadtripChinese'
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    Copy-Item -LiteralPath 'src\bin\Release\MonsterRoadtripChinese.dll' -Destination $pluginDir -Force
    dotnet build compat\MonsterRoadtripMonoCompat.csproj --configuration Release --ignore-failed-sources
    if ($LASTEXITCODE -ne 0) { throw 'Mono layout helper build failed.' }
    & tools\build-mono-compat.ps1
    & tools\tests\test-mono-compat.ps1
    $coreDir = Join-Path $projectRoot 'build\package\BepInEx\core'
    New-Item -ItemType Directory -Path $coreDir -Force | Out-Null
    Copy-Item -LiteralPath 'build\mono-compat\MonoMod.Utils.dll','build\mono-compat\MonsterRoadtripMonoCompat.dll' -Destination $coreDir -Force
    Copy-Item -LiteralPath 'compat\LICENSE-MonoMod.txt' -Destination (Join-Path $coreDir 'MonsterRoadtripMonoCompat.LICENSE.txt') -Force
    Write-Host "Build complete: $pluginDir"
}
finally {
    Pop-Location
}

