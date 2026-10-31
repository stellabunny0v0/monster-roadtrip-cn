param([string]$GameDir = $env:MONSTER_ROADTRIP_GAME_DIR)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($GameDir)) {throw 'Pass -GameDir or set MONSTER_ROADTRIP_GAME_DIR.'}
$gameRoot = [IO.Path]::GetFullPath($GameDir).TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $gameRoot 'MonsterRoadtrip.exe') -PathType Leaf)) {throw 'Game executable not found.'}
if (Get-Process -Name MonsterRoadtrip -ErrorAction SilentlyContinue) {throw 'Exit the game normally before installing.'}
$core = Join-Path $gameRoot 'BepInEx\core'
$utils = Join-Path $core 'MonoMod.Utils.dll'
$helper = Join-Path $core 'MonsterRoadtripMonoCompat.dll'
$saveRoot = Join-Path $gameRoot 'UserData'
$configRoot = Join-Path $gameRoot 'BepInEx\config'
foreach ($path in @($gameRoot,(Join-Path $gameRoot 'BepInEx'),$core,$utils,$helper,$saveRoot,$configRoot)) {
    if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint)) {throw "Unexpected reparse point: $path"}
}
$source = Join-Path $repoRoot 'build\mono-compat'
$manifest = Get-Content -LiteralPath (Join-Path $source 'compatibility-manifest.json') -Raw | ConvertFrom-Json
$knownOriginal = '9D1495F147AC93C4F81F84538C1A326E8F8A6AEFC78D6289D798F3CE1162C5E9'
if ($manifest.originalSha256 -ne $knownOriginal) {throw 'Unsupported backport manifest.'}
$sourceUtils = Join-Path $source 'MonoMod.Utils.dll'
$sourceHelper = Join-Path $source 'MonsterRoadtripMonoCompat.dll'
if ((Get-FileHash -LiteralPath $sourceUtils -Algorithm SHA256).Hash -ne $manifest.patchedSha256 -or
    (Get-FileHash -LiteralPath $sourceHelper -Algorithm SHA256).Hash -ne $manifest.helperSha256) {throw 'Built file hash mismatch.'}
$currentHash = (Get-FileHash -LiteralPath $utils -Algorithm SHA256).Hash
if ($currentHash -eq $manifest.patchedSha256 -and (Test-Path -LiteralPath $helper) -and
    (Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash -eq $manifest.helperSha256) {
    Write-Output 'Mono layout compatibility fix is already installed.'
    exit 0
}
if ($currentHash -ne $knownOriginal) {throw 'A different or modified MonoMod.Utils is installed. No files changed.'}
if (Test-Path -LiteralPath $helper) {throw 'Compatibility helper already exists with different contents. No files changed.'}
function Get-Inventory([string]$root, [string[]]$exclude = @()) {
    $result = [ordered]@{}
    if (Test-Path -LiteralPath $root) {
        foreach ($file in (Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName)) {
            if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) {throw 'Unexpected linked inventory file.'}
            $name = $file.FullName.Substring($root.Length).TrimStart('\')
            if ($name -notin $exclude) { $result[$name] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
        }
    }
    return $result
}
$savesBefore = Get-Inventory $saveRoot
$configBefore = Get-Inventory $configRoot
$otherCoreBefore = Get-Inventory $core @('MonoMod.Utils.dll','MonsterRoadtripMonoCompat.dll')
$backup = Join-Path $repoRoot ('backups\mono-layout-before-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $backup | Out-Null
Copy-Item -LiteralPath $utils -Destination (Join-Path $backup 'MonoMod.Utils.dll')
if (Test-Path -LiteralPath $saveRoot) {Copy-Item -LiteralPath $saveRoot -Destination (Join-Path $backup 'UserData') -Recurse}
$savesBefore | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backup 'save-hashes-before.json') -Encoding utf8
if (Get-Process -Name MonsterRoadtrip -ErrorAction SilentlyContinue) {throw 'Game started during preparation; no files installed.'}
# Write the dependency before the patched caller. The original library is backed up above.
Copy-Item -LiteralPath $sourceHelper -Destination $helper
Copy-Item -LiteralPath $sourceUtils -Destination $utils -Force
if ((Get-FileHash -LiteralPath $utils -Algorithm SHA256).Hash -ne $manifest.patchedSha256 -or
    (Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash -ne $manifest.helperSha256) {throw "Installed file mismatch. Backup: $backup"}
if (($savesBefore | ConvertTo-Json -Compress) -cne ((Get-Inventory $saveRoot) | ConvertTo-Json -Compress)) {throw 'UserData changed during installation; inspect before launching.'}
if (($configBefore | ConvertTo-Json -Compress) -cne ((Get-Inventory $configRoot) | ConvertTo-Json -Compress)) {throw 'Configuration changed during installation.'}
if (($otherCoreBefore | ConvertTo-Json -Compress) -cne ((Get-Inventory $core @('MonoMod.Utils.dll','MonsterRoadtripMonoCompat.dll')) | ConvertTo-Json -Compress)) {throw 'Unexpected core file change.'}
$report = [ordered]@{
    fix='mono-layout-1'; installed=$true; installedAt=(Get-Date).ToString('o');
    changedFiles=2; originalLibraryBackedUp=$true; backupDirectory=$backup;
    saveFilesChecked=$savesBefore.Count; savesUnchanged=$true; configurationUnchanged=$true;
    unrelatedCoreFilesUnchanged=$true; gameLaunched=$false;
    patchedSha256=$manifest.patchedSha256; helperSha256=$manifest.helperSha256
}
$report | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backup 'installation-report.json') -Encoding utf8
$report | ConvertTo-Json
