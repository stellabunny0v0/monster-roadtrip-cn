$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Add-Type -Path @(
    (Join-Path $projectRoot 'src/StatDisplayTranslations.cs'),
    (Join-Path $PSScriptRoot 'StatContractsHarness.cs')
)
[StatContractsHarness]::Run(
    (Join-Path $projectRoot 'extracted/original'),
    (Join-Path $projectRoot 'build/package/BepInEx/plugins/MonsterRoadtripChinese/Translation'))
