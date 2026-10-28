# Monster Prom 3 - Monster Roadtrip 简体中文 Mod

适用于 Steam Windows 版 **Monster Prom 3 - Monster Roadtrip** 的简体中文 Mod。

当前源码版本：**v0.3.3**。30,255 条文本已完成语言审校，原 PENDING 的 109 条疑难项已逐条裁决，其中 56 条保留、25 条纠错、28 条润色。59 条英文动词变量新增按行中文展开适配，已通过离线测试及编译，尚待实机验收。详见 [审校明细](docs/review/pending-review-109.md)。

本轮更新源码，尚未发布新版安装包。以下安装步骤对应原 v0.3.2 发行包；本轮译文及动词适配需使用 v0.3.3 源码构建的插件和同批次翻译文件。

## 汉化效果

### 主菜单

![Monster Prom 3 - Monster Roadtrip 汉化后的主菜单](docs/images/preview-main-menu.jpg)

### 剧情对话

![Monster Prom 3 - Monster Roadtrip 汉化后的剧情对话](docs/images/preview-dialogue.jpg)

### 事件选项

![Monster Prom 3 - Monster Roadtrip 汉化后的事件选项](docs/images/preview-choice.jpg)

## 安装

1. 打开 [Releases 页面](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/latest)。
2. 下载 `MonsterRoadtripChinese-v0.3.2-Windows-x86.zip`。
3. 完全退出游戏。
4. 在 Steam 库中右键游戏，选择“管理”→“浏览本地文件”。
5. 把压缩包内的所有文件直接解压到游戏根目录，也就是 `MonsterRoadtrip.exe` 所在的文件夹。出现合并文件夹提示时选择允许。
6. 正常通过 Steam 启动游戏。第一次启动可能比平时稍慢。

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

Mod 每次启动时还会在游戏读取进度前，把现有 XML 存档复制到：

```text
BepInEx\save-backups\cn.monsterroadtrip.localization\<时间戳>\
```

自动备份只复制文件，不会删除、移动或覆盖原存档。卸载整个 BepInEx 文件夹前，如需保留这些自动备份，请先把 `save-backups` 复制到别处。

## 删除 Mod

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
```

## 第三方组件

发行包包含 [BepInEx 5.4.23.5](https://github.com/BepInEx/BepInEx/releases/tag/v5.4.23.5)（MIT License）。详情见 `THIRD-PARTY-NOTICES.md`。
