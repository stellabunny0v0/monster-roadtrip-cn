$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Add-Type -Path (Join-Path $root 'src\SaveDataPaths.cs')
$type=([AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object {$_.GetType('MonsterRoadtripChinese.SaveDataPaths')} | Where-Object {$_} | Select-Object -First 1)
$method=$type.GetMethod('Candidates',[Reflection.BindingFlags]'Static,NonPublic')
$fixture=Join-Path $root '.cache\save-path-layout-fixture'
$data=Join-Path $fixture 'MonsterRoadtrip_Data'
$win=$method.Invoke($null,[object[]]@([string]$fixture,[string]$data,[bool]$false))
if($win.Count -ne 1 -or $win[0] -ne (Join-Path $fixture 'UserData')){throw 'Windows backup location changed'}
$app=Join-Path $fixture 'Monster Roadtrip.app'
$mac=$method.Invoke($null,[object[]]@([string]$fixture,[string](Join-Path $app 'Contents'),[bool]$true))
if($mac.Count -ne 2 -or $mac[0] -ne (Join-Path $app 'UserData') -or $mac[1] -ne (Join-Path $fixture 'UserData')){throw 'Mac primary/legacy paths incorrect or duplicated'}
$alternate=$method.Invoke($null,[object[]]@([string]$fixture,[string](Join-Path $app 'Contents\Resources\Data'),[bool]$true))
if($alternate.Count -ne 3 -or $alternate[0] -ne (Join-Path $app 'Contents\Resources\UserData')){throw 'Alternate layout is not derived from application data path'}
'PASS: Windows path unchanged; Mac data-path and legacy sources resolved without touching files.'
