param(
    [string]$GameDir = $env:MONSTER_ROADTRIP_GAME_DIR,
    [string]$SteamRemoteDir
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupRoot = Join-Path $projectRoot 'backups\saves'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$destination = Join-Path $backupRoot $timestamp

if ([string]::IsNullOrWhiteSpace($GameDir)) {
    throw 'Pass -GameDir or set MONSTER_ROADTRIP_GAME_DIR first.'
}

$userData = Join-Path $GameDir 'UserData'

if (-not (Test-Path -LiteralPath $userData -PathType Container)) {
    throw "Game save directory was not found: $userData"
}

New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath $userData -Destination (Join-Path $destination 'UserData') -Recurse

if (-not [string]::IsNullOrWhiteSpace($SteamRemoteDir)) {
    $remoteCache = Join-Path $SteamRemoteDir 'remotecache.vdf'
    if (Test-Path -LiteralPath $remoteCache -PathType Leaf) {
        Copy-Item -LiteralPath $remoteCache -Destination $destination
    }
}

$logFiles = @(
    (Join-Path $GameDir 'BepInEx\LogOutput.log'),
    (Join-Path $env:USERPROFILE 'AppData\LocalLow\Beautiful Glitch\Monster Roadtrip\Player.log'),
    (Join-Path $env:USERPROFILE 'AppData\LocalLow\Beautiful Glitch\Monster Roadtrip\Player-prev.log')
)
$logDestination = Join-Path $destination 'Logs'
foreach ($logFile in $logFiles) {
    if (Test-Path -LiteralPath $logFile -PathType Leaf) {
        New-Item -ItemType Directory -Path $logDestination -Force | Out-Null
        Copy-Item -LiteralPath $logFile -Destination $logDestination
    }
}

$checksums = Get-ChildItem -LiteralPath $destination -Recurse -File |
    Where-Object { $_.Name -ne 'SHA256SUMS.txt' } |
    Sort-Object FullName |
    ForEach-Object {
        $relativePath = $_.FullName.Substring($destination.Length + 1)
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        "$hash  $relativePath"
    }
$checksums | Set-Content -LiteralPath (Join-Path $destination 'SHA256SUMS.txt') -Encoding utf8

Write-Host "Save backup created: $destination"
