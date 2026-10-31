#Requires -Version 5.1
param(
    [ValidateSet('Install','Uninstall')][string]$Mode = 'Install',
    [string]$GameDir = '',
    [string]$BackupRoot = '',
    [switch]$ValidateOnly,
    [switch]$NonInteractive
)
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$payloadRoot = Join-Path $packageRoot 'payload'
$stateRelative = 'BepInEx\MonsterRoadtripChinese.install.json'

function Get-SafePath([string]$Root,[string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative) -or
        $Relative -match '(^|[\\/])\.\.?([\\/]|$)|:') {throw '安装记录包含不安全的相对路径。'}
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $path = [IO.Path]::GetFullPath((Join-Path $base $Relative))
    if (-not $path.StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase)) {throw '目标路径超出游戏目录。'}
    $cursor = $path
    while ($cursor.Length -ge $base.Length) {
        if ($cursor -ne $path -and (Test-Path -LiteralPath $cursor -PathType Leaf)) {throw "父路径是文件，不能安装：$cursor"}
        if ((Test-Path -LiteralPath $cursor) -and
            ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {throw "为保护文件，停止处理链接路径：$cursor"}
        if ($cursor -eq $base) {break}
        $cursor = Split-Path -Parent $cursor
    }
    return $path
}
function Get-Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Get-SaveInventory([string]$Root) {
    $result = [ordered]@{}
    if (Test-Path -LiteralPath $Root) {
        foreach ($file in (Get-ChildItem -LiteralPath $Root -Recurse -File | Sort-Object FullName)) {
            $relative = $file.FullName.Substring($Root.Length).TrimStart('\')
            $safe = Get-SafePath $Root $relative
            $result[$relative] = Get-Hash $safe
        }
    }
    return $result
}
function Assert-NoGame {
    if (Get-Process -Name MonsterRoadtrip -ErrorAction SilentlyContinue) {throw '请先正常退出 Monster Roadtrip，再运行安装或卸载。'}
}
function Find-Game {
    $steamRoots = @()
    foreach ($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam')) {
        $value = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if ($null -ne $value) {
            foreach ($name in @('SteamPath','InstallPath')) {if ($value.$name) {$steamRoots += [string]$value.$name}}
        }
    }
    $libraries = @($steamRoots)
    foreach ($root in $steamRoots) {
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($match in [regex]::Matches([IO.File]::ReadAllText($vdf),'"path"\s+"([^"]+)"')) {
                $libraries += $match.Groups[1].Value.Replace('\\','\')
            }
        }
    }
    $candidates = @($libraries | Sort-Object -Unique | ForEach-Object {
        $candidate = Join-Path $_ 'steamapps\common\Monster Prom 3 - Monster Roadtrip'
        if (Test-Path -LiteralPath (Join-Path $candidate 'MonsterRoadtrip.exe') -PathType Leaf) {$candidate}
    })
    if ($candidates.Count -eq 1) {return $candidates[0]}
    if ($NonInteractive) {throw '无法唯一定位游戏，请传入 -GameDir。'}
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = '选择 MonsterRoadtrip.exe 所在的游戏文件夹（不是安装包文件夹）'
    $dialog.ShowNewFolderButton = $false
    try {
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {throw '已取消，没有安装或卸载。'}
        return $dialog.SelectedPath
    } finally { $dialog.Dispose() }
}
function Write-Json([string]$Path,$Value) {
    $Value | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function Assert-PayloadPath([string]$Relative,[string]$Kind) {
    $normalized = $Relative.Replace('/','\')
    if ($Kind -eq 'plugin' -and $normalized -match '^BepInEx\\plugins\\MonsterRoadtripChinese\\(MonsterRoadtripChinese\.dll|Translation\\schinese_(events_[a-z]+\.txt|metatexts\.json|verb_overrides\.tsv))$') {return}
    if ($Kind -eq 'loader' -and ($normalized -match '^BepInEx\\core\\[A-Za-z0-9_.-]+\.(dll|txt)$' -or
        $normalized -in @('winhttp.dll','doorstop_config.ini','.doorstop_version','changelog.txt'))) {return}
    throw "安装包包含范围以外的文件：$Relative"
}

try {
    if ([Environment]::OSVersion.Version.Major -lt 10) {throw '此安装包面向 Windows 10 / 11，不支持旧版 Windows。'}
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {throw 'Windows ARM 尚未实测，此安装包暂不自动安装。'}
    Assert-NoGame
    if (-not $GameDir) {$GameDir = Find-Game}
    $gameRoot = [IO.Path]::GetFullPath($GameDir).TrimEnd('\')
    if (-not (Test-Path -LiteralPath (Get-SafePath $gameRoot 'MonsterRoadtrip.exe') -PathType Leaf)) {throw '所选目录中没有 MonsterRoadtrip.exe。'}
    $statePath = Get-SafePath $gameRoot $stateRelative
    $saveRoot = Get-SafePath $gameRoot 'UserData'

    if ($Mode -eq 'Uninstall') {
        if (-not (Test-Path -LiteralPath $statePath)) {throw '未找到本安装器的记录；请按说明手动删除汉化插件，避免误删其他 Mod。'}
        $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($state.format -ne 1 -or $state.gameRoot -ne $gameRoot) {throw '安装记录不匹配当前游戏目录。'}
        $otherPlugins = @()
        $pluginsRoot = Get-SafePath $gameRoot 'BepInEx\plugins'
        if (Test-Path -LiteralPath $pluginsRoot) {
            $ownRoot = Get-SafePath $gameRoot 'BepInEx\plugins\MonsterRoadtripChinese'
            $otherPlugins = @(Get-ChildItem -LiteralPath $pluginsRoot -Recurse -File -Filter '*.dll' | Where-Object {
                -not $_.FullName.StartsWith($ownRoot+'\',[StringComparison]::OrdinalIgnoreCase)
            })
        }
        $keepLoader = [bool]$state.loaderExisted -or $otherPlugins.Count -gt 0
        $toRemove = @()
        foreach ($record in $state.records) {
            Assert-PayloadPath $record.path $record.kind
            if ($record.kind -eq 'loader' -and ($keepLoader -or -not $record.created)) {continue}
            $path = Get-SafePath $gameRoot $record.path
            if (Test-Path -LiteralPath $path) {
                if ((Get-Hash $path) -ne $record.installedSha256) {throw "文件在安装后被修改，已停止卸载以免覆盖你的改动：$($record.path)"}
                $toRemove += $path
            }
        }
        if ($ValidateOnly) {Write-Host "卸载检查通过：$($toRemove.Count) 个文件；保留加载器：$keepLoader"; exit 0}
        Assert-NoGame
        $savesBefore = Get-SaveInventory $saveRoot
        foreach ($path in $toRemove) {Remove-Item -LiteralPath $path -Force}
        Remove-Item -LiteralPath $statePath -Force
        if (($savesBefore | ConvertTo-Json -Compress) -cne ((Get-SaveInventory $saveRoot) | ConvertTo-Json -Compress)) {throw '存档在卸载过程中发生变化，请先核对备份。'}
        Write-Host '汉化已卸载；UserData 和备份均保留。'
        if ($keepLoader) {Write-Host '保留原有 BepInEx、退出兼容补丁和其他 Mod。'}
        Write-Host "安装前备份：$($state.backupDirectory)"
        exit 0
    }

    if ($gameRoot -match '[^\x00-\x7F]') {throw '当前游戏的 Unity 运行时在中文安装路径下存在已知问题。请用 Steam 的移动安装功能移到英文路径后安装；安装包解压路径可以含中文。'}
    $manifestPath = Join-Path $packageRoot 'package-manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($manifest.format -ne 1) {throw '不支持的安装包格式。'}
    foreach ($item in $manifest.gameFiles) {
        $path = Get-SafePath $gameRoot $item.path
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Hash $path) -ne $item.sha256) {throw "游戏版本与已测试版本不同，停止安装：$($item.path)。请等待匹配的 Mod 版本。"}
    }
    if (Test-Path -LiteralPath $statePath) {
        $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($state.format -ne 1 -or $state.gameRoot -ne $gameRoot -or $state.packageVersion -ne $manifest.version) {throw '已有其他版本的安装记录，请先用旧包卸载汉化再安装新版。'}
        foreach ($record in $state.records) {
            Assert-PayloadPath $record.path $record.kind
            $path = Get-SafePath $gameRoot $record.path
            if (-not (Test-Path -LiteralPath $path) -or (Get-Hash $path) -ne $record.installedSha256) {throw '已安装文件发生变化，请先核对备份，不会自动覆盖。'}
        }
        Write-Host '这个版本已经安装且文件完整，无需重复安装。'
        exit 0
    }
    $loaderExisted = (Test-Path -LiteralPath (Get-SafePath $gameRoot 'BepInEx\core\BepInEx.dll')) -or
        (Test-Path -LiteralPath (Get-SafePath $gameRoot 'winhttp.dll'))
    $records = @()
    $seen = @{}
    foreach ($item in $manifest.files) {
        Assert-PayloadPath $item.path $item.kind
        if ($seen.ContainsKey($item.path)) {throw '安装包清单存在重复路径。'}
        $seen[$item.path] = $true
        $source = Get-SafePath $payloadRoot $item.path
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or (Get-Hash $source) -ne $item.sha256) {throw "安装包校验失败，请重新下载：$($item.path)"}
        $destination = Get-SafePath $gameRoot $item.path
        $exists = Test-Path -LiteralPath $destination -PathType Leaf
        $beforeHash = if ($exists) {Get-Hash $destination} else {''}
        $keepExisting = $false
        if ($exists -and $item.kind -eq 'loader' -and $beforeHash -ne $item.sha256) {
            if ($item.path -eq 'doorstop_config.ini') {
                $cfg = [IO.File]::ReadAllText($destination)
                if ($cfg -match '(?m)^enabled\s*=\s*true\s*$' -and $cfg -match '(?mi)^target_assembly\s*=\s*BepInEx[\\/]core[\\/]BepInEx\.Preloader\.dll\s*$') {$keepExisting=$true}
                else {throw '现有 Doorstop 配置与此安装包不兼容，已停止，不会覆盖配置。'}
            } elseif ($beforeHash -notin @($item.allowedExistingSha256)) {throw "检测到不同版本或其他 Mod 的加载器，已停止：$($item.path)"}
        }
        $installedHash = if ($keepExisting) {$beforeHash} else {$item.sha256}
        $records += [pscustomobject]@{path=$item.path;kind=$item.kind;created=(-not $exists);beforeSha256=$beforeHash;installedSha256=$installedHash;write=(-not $keepExisting -and $beforeHash -ne $item.sha256)}
    }
    if ($ValidateOnly) {Write-Host "安装检查通过：$($manifest.version)，$($records.Count) 个文件。"; exit 0}
    if (-not $BackupRoot) {$BackupRoot = Join-Path $env:LOCALAPPDATA 'MonsterRoadtripChinese\backups'}
    $backupBase = [IO.Path]::GetFullPath($BackupRoot).TrimEnd('\')
    if ($backupBase -eq $gameRoot -or $backupBase.StartsWith($gameRoot+'\',[StringComparison]::OrdinalIgnoreCase)) {throw '备份目录必须位于游戏目录之外。'}
    $backup = Get-SafePath $backupBase ((Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    $savesBefore = Get-SaveInventory $saveRoot
    if (Test-Path -LiteralPath $saveRoot) {Copy-Item -LiteralPath $saveRoot -Destination (Join-Path $backup 'UserData') -Recurse}
    foreach ($record in $records) {
        if ($record.beforeSha256 -and $record.write) {
            $old = Get-SafePath $gameRoot $record.path
            $copy = Get-SafePath (Join-Path $backup 'previous') $record.path
            New-Item -ItemType Directory -Path (Split-Path -Parent $copy) -Force | Out-Null
            Copy-Item -LiteralPath $old -Destination $copy
            if ((Get-Hash $copy) -ne $record.beforeSha256) {throw '旧文件备份校验失败，尚未安装。'}
        }
    }
    if (($savesBefore | ConvertTo-Json -Compress) -cne ((Get-SaveInventory (Join-Path $backup 'UserData')) | ConvertTo-Json -Compress)) {throw '存档副本校验失败，尚未安装。'}
    $state = [ordered]@{format=1;packageVersion=$manifest.version;gameRoot=$gameRoot;backupDirectory=$backup;loaderExisted=[bool]$loaderExisted;records=$records}
    Write-Json (Join-Path $backup 'installation-record.json') $state
    Write-Json (Join-Path $backup 'save-hashes.json') $savesBefore
    Write-Host "备份完成：$backup"
    Assert-NoGame
    $written = @()
    try {
        foreach ($record in $records) {
            if (-not $record.write) {continue}
            $destination = Get-SafePath $gameRoot $record.path
            $source = Get-SafePath $payloadRoot $record.path
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            $written += $record
            Copy-Item -LiteralPath $source -Destination $destination -Force
            if ((Get-Hash $destination) -ne $record.installedSha256) {throw '安装后校验失败。'}
        }
        if (($savesBefore | ConvertTo-Json -Compress) -cne ((Get-SaveInventory $saveRoot) | ConvertTo-Json -Compress)) {throw '存档在安装过程中发生变化，请核对备份。'}
        New-Item -ItemType Directory -Path (Split-Path -Parent $statePath) -Force | Out-Null
        Write-Json $statePath $state
    } catch {
        $installError = $_
        # Roll back only this transaction's file writes, never UserData.
        [array]::Reverse($written)
        foreach ($record in $written) {
            $destination = Get-SafePath $gameRoot $record.path
            if ($record.beforeSha256) {Copy-Item -LiteralPath (Get-SafePath (Join-Path $backup 'previous') $record.path) -Destination $destination -Force}
            elseif (Test-Path -LiteralPath $destination) {Remove-Item -LiteralPath $destination -Force}
        }
        throw $installError
    }
    Write-Host "安装完成：$($manifest.version)。请通过 Steam 正常启动游戏。"
    Write-Host "存档与旧文件备份：$backup"
    Write-Host '卸载时双击同一安装包中的 uninstall.bat。'
    exit 0
} catch {
    Write-Host ('已停止：'+$_.Exception.Message) -ForegroundColor Red
    exit 1
}
