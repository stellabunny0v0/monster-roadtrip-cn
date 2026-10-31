$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Add-Type -Path @(
    (Join-Path $projectRoot 'src/NameTextPersistence.cs'),
    (Join-Path $PSScriptRoot 'NamePersistenceHarness.cs')
)
[NamePersistenceHarness]::Run()
