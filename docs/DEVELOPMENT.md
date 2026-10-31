# 开发与构建

源码位于 `src`，翻译工作表位于 `translation`，构建和校验脚本位于 `tools`。构建需要本地游戏程序集、BepInEx 5.4.23.5 和 .NET SDK；不向仓库或发行包加入游戏程序、存档或本机配置。

```powershell
$env:MONSTER_ROADTRIP_GAME_DIR = 'D:\SteamLibrary\steamapps\common\Monster Prom 3 - Monster Roadtrip'
.\build.ps1
```

动词展开配置在 `translation/runtime_verb_overrides_zh.json`。生成的 `Translation/schinese_verb_overrides.tsv` 必须与插件和翻译表一起打包；不能只更新 DLL。游戏结算指令和变量遵循现有校验规则，勿把执行标记直接改成中文。

离线校验：

```powershell
python -m unittest discover -s tools/tests -p 'test_*.py'
.\tools\tests\test-runtime-verbs.ps1
.\tools\tests\test-stat-contracts.ps1
.\tools\tests\test-name-persistence.ps1
.\tools\tests\test-name-hook.ps1 -GameDir $env:MONSTER_ROADTRIP_GAME_DIR
.\tools\tests\test-mono-compat.ps1
.\tools\tests\test-save-paths.ps1
```

Windows 打包：`python tools/package_windows_installer.py --game-dir "$env:MONSTER_ROADTRIP_GAME_DIR" --version <版本>`。使用 Windows PowerShell 5.1，不持久修改执行策略。不要覆盖已发布版本的 ZIP。

Mac 打包：在 `.tools/bepinex-macos` 准备官方 Mac 加载器，在 `.tools/downloads` 保留原始 `BepInEx_macos_universal_5.4.23.5.zip`；先编译 `src`，准备已验证的 `build/package` 翻译文件及 `build/mono-compat`，再运行 `python tools/package_macos_installer.py`。Mac 包使用本次编译的 DLL，不复用 Windows 包内旧 DLL。ZIP 单独设置 Unix 执行权限与 LF 换行；脚本兼容系统 Bash 3.2。

两个平台分别打包。没有 Mac 真机验证前，Mac 必须作为 prerelease 发布，并保持实验版标识。安装器与当前验证范围见 [INSTALLER_PLATFORMS.md](INSTALLER_PLATFORMS.md)。
