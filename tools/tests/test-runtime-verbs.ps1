$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Add-Type -Path @(
    (Join-Path $projectRoot 'src/RuntimeVerbTranslations.cs'),
    (Join-Path $PSScriptRoot 'RuntimeVerbHarness.cs')
)
[RuntimeVerbHarness]::Run((Join-Path $projectRoot 'build/package/BepInEx/plugins/MonsterRoadtripChinese/Translation'))
