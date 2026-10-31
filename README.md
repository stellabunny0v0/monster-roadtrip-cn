# Monster Prom 3 - Monster Roadtrip 简体中文 Mod

适用于 Steam Windows 版 **Monster Prom 3 - Monster Roadtrip** 的简体中文 Mod。

当前源码版本：**v0.3.6**。30,255 条文本已完成语言审校，原 PENDING 的 109 条疑难项已逐条裁决，其中 56 条保留、25 条纠错、28 条润色。59 条英文动词变量新增按行中文展开适配，已通过离线测试及编译，尚待实机验收。详见 [审校明细](docs/review/pending-review-109.md)。

最新 **[Windows 一键安装包 `v0.3.6-mono-layout-1`](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/tag/v0.3.6-mono-layout-1)** 已发布，包含退出兼容补丁和安装／卸载入口。旧 v0.3.2 不包含这些更新。

v0.3.4 修复了中文属性名导致游戏无法识别加减分的问题：构建时恢复结算协议，游戏完成原有结算后再显示中文。右上角六项属性名也改为中文；保留游戏原有倍率、乘客效果和结算时机。详见 [修复说明](docs/review/stat-runtime-fix-001.md)。

v0.3.5 修复中文姓名保存后变成 `???` 的编码问题，并补齐 83 个地图／目的地标题的中文名称。已损坏的姓名只能按明确提供的原名恢复，插件默认不猜测；本机恢复规则和旧存档不随发行包分发。详见 [姓名与地点修复说明](docs/review/name-location-runtime-fix-001.md)。

v0.3.6 把主角选择界面的颜色称呼改为“蓝／绿／红／黄／肉桂／紫／橙／绿松石”，不改玩家自定义姓名。`mono-layout-1` 修复了加载器底层的一处 Unity／Mono 兼容问题；本机隔离副本已正常退出三次，包含设置返回测试。详见 [退出修复说明](docs/review/quit-crash-fix-002.md)。

## 安装

从 [最新 Release](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/tag/v0.3.6-mono-layout-1) 下载 **[MonsterRoadtripChinese-v0.3.6-mono-layout-1-Windows.zip](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/download/v0.3.6-mono-layout-1/MonsterRoadtripChinese-v0.3.6-mono-layout-1-Windows.zip)**。请选择 Assets 中的安装包，`Source code` 不是安装包。

1. 将压缩包**完整解压**到任意文件夹，不要直接在压缩包内运行。
2. 正常退出游戏，双击 `install.bat`。
3. 安装器会查找 Steam 游戏目录；找不到时，选择 `MonsterRoadtrip.exe` 所在文件夹。
4. 等待显示“安装完成”，之后通过 Steam 正常启动游戏。

无需另外安装 Python、dotnet SDK 或 BepInEx。安装前会校验包内文件、游戏版本和已有加载器，复制备份存档与将被覆盖的旧文件；不匹配时停止，不自动覆盖其他版本加载器，也不自动申请管理员权限。

目标平台为 Windows 10／11 的 Intel／AMD 电脑。Windows 11 已做本机验证，Windows 10 尚待实机验证；Windows ARM、旧版 Windows 和 macOS 不在本包验证范围。当前游戏的 Unity 在中文安装路径下有已知问题，安装器会提示使用 Steam 将游戏移至英文路径；安装包解压目录可以含中文。

旧 v0.3.2 包没有 `install.bat`，仍需把包内文件直接解压到游戏根目录。

安装正确后，游戏根目录中应能看到：

```text
BepInEx\plugins\MonsterRoadtripChinese\
doorstop_config.ini
winhttp.dll
```

本安装包已经包含 Windows x86 版 BepInEx 5.4.23.5，无需另外下载加载器。

## 安装前备份存档

建议安装前手动备份一次：

1. 完全退出游戏。
2. 在 Steam 库中右键游戏，选择“管理”→“浏览本地文件”。
3. 找到游戏根目录下的 `UserData` 文件夹。
4. 把整个 `UserData` 文件夹复制到桌面或其他安全位置，并给副本加上日期。

新版安装器还会自动复制一份存档和旧文件到 `%LOCALAPPDATA%\MonsterRoadtripChinese\backups\<时间戳>`，完成后显示实际路径。自动备份不替代自行保留的长期备份。

Mod 每次启动时还会在游戏读取进度前，把现有 XML 存档复制到：

```text
BepInEx\save-backups\cn.monsterroadtrip.localization\<时间戳>\
```

自动备份只复制文件，不会删除、移动或覆盖原存档。卸载整个 BepInEx 文件夹前，如需保留这些自动备份，请先把 `save-backups` 复制到别处。

## 删除 Mod

使用新版一键包安装时：退出游戏，双击同包的 `uninstall.bat`。保留 `UserData`、备份和已有配置。安装前已有 BepInEx，或安装后又加入其他 Mod 时，会保留共享加载器及退出兼容补丁；如果加载器由本包首次安装且没有其他 Mod，则移除本包创建的加载器文件。安装后的文件若被用户修改，卸载器会停止并提示，避免误删改动。

手动安装的旧版本可按以下方式删除：

如果还在使用其他 BepInEx Mod，只删除：

```text
BepInEx\plugins\MonsterRoadtripChinese
```

如果 BepInEx 只用于本汉化，可以删除以下内容：

```text
BepInEx
.doorstop_version
changelog.txt
doorstop_config.ini
winhttp.dll
THIRD-PARTY-NOTICES.md
```

删除 Mod 不需要删除 `UserData`，也不会重置游戏存档。如果无法确定 BepInEx 是否还被其他 Mod 使用，只删除汉化插件文件夹即可。

## 反馈问题

反馈时请说明出现问题的场景，并附上游戏根目录中的 `BepInEx\LogOutput.log`。如果是翻译问题，最好附上截图或对应英文原句。

## 开发与构建

源码位于 `src`，翻译工作表位于 `translation`，构建和校验脚本位于 `tools`。本地构建需要自行准备 BepInEx x86 5.4.23.5，并设置游戏目录：

```powershell
$env:MONSTER_ROADTRIP_GAME_DIR = 'D:\SteamLibrary\steamapps\common\Monster Prom 3 - Monster Roadtrip'
.\build.ps1
```

人物口吻和术语规则见 `docs/STYLE_GUIDE_ZH.md`。

动词展开配置在 `translation/runtime_verb_overrides_zh.json`。构建生成的 `Translation/schinese_verb_overrides.tsv` 必须随插件和翻译表一起打包，不能只更新 DLL。翻译 CSV 与事件表保留源文变量；插件在加载中文事件时按行号、完整文本匹配应用已审的展开结果。

额外离线验证：

```powershell
python -m unittest discover -s tools/tests -p 'test_*.py'
.\tools\tests\test-runtime-verbs.ps1
.\tools\tests\test-stat-contracts.ps1
.\tools\tests\test-name-persistence.ps1
.\tools\tests\test-name-hook.ps1 -GameDir $env:MONSTER_ROADTRIP_GAME_DIR
.\tools\tests\test-mono-compat.ps1
```

构建一键包：`python tools/package_windows_installer.py --game-dir "$env:MONSTER_ROADTRIP_GAME_DIR"`。安装器使用 Windows 自带的 PowerShell 5.1；`.bat` 只为此次进程设置脚本执行方式，不修改系统执行策略。当前包没有数字签名，请只从项目来源下载；哈希校验用于检查损坏，不能替代来源可信性。

Mac 版需要独立的加载器、`.command` 入口、游戏与存档路径适配，并在 Intel／Apple Silicon 环境验证；计划见 [跨平台发布说明](docs/INSTALLER_PLATFORMS.md)。

## 第三方组件

发行包包含 [BepInEx 5.4.23.5](https://github.com/BepInEx/BepInEx/releases/tag/v5.4.23.5)（MIT License）。详情见 `THIRD-PARTY-NOTICES.md`。
