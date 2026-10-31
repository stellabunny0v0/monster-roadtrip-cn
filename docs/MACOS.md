# macOS 实验版安装说明

适用于 Steam 版 **Monster Prom 3 - Monster Roadtrip**，游戏进程必须是 **x86_64 Mono**。Intel Mac 直接运行；Apple Silicon 通过 Rosetta 运行。暂不支持纯 arm64 或 IL2CPP 游戏程序。

**本包尚未在 Mac 真机验证。** 安装脚本的离线测试不能代表游戏运行兼容性；中文字体、姓名保存、属性结算、设置返回和退出仍需实机确认。Windows 用户请使用 Windows 安装包。

## 安装

1. 退出游戏，先按下文备份存档。
2. 从本项目 Release 下载名称含 `macOS.zip` 的实验包，完整解压。
3. 双击 `install.command`。默认查找 Steam 常用目录；找不到时，在弹出的窗口选择游戏 `.app`。自定义 Steam 库可按下一节从终端指定路径。
4. 等待“安装完成”，将终端显示的整行命令复制到 Steam → 游戏“属性”→“通用”→“启动选项”。形如：

   ```text
   "/bin/bash" "/你的游戏目录/monster_roadtrip_cn.sh" %command%
   ```

5. 通过 Steam 启动游戏。保留解压后的安装包，以便以后卸载。

安装器不修改 `.app` 的游戏文件、Steam 配置或存档，不自动申请管理员权限，不安装 Rosetta。Apple Silicon 如缺少 Rosetta，请按系统提示完成安装后重试。请保留原来的 Steam 启动选项；若已配置其他启动包装器，先自行确认组合方式，不要直接覆盖它。

### 从终端运行

若双击没有打开终端，可打开“终端”，输入 `/bin/bash `（末尾有空格），把 `install.command` 拖入窗口，再按回车。也可以明确指定游戏：

```bash
/bin/bash "/解压目录/install.command" "/Steam库/steamapps/common/Monster Prom 3 - Monster Roadtrip"
```

路径含空格时保留引号。若 macOS 提示无法验证开发者，请核对下载来源，再通过系统“隐私与安全性”中针对此文件的选项允许打开；本项目不要求全局关闭 Gatekeeper 或 SIP。不提供自动清除整个游戏隔离标记或自动重新签名的操作。若系统仍拦截 `libdoorstop.dylib`，请保留错误信息反馈，勿盲目修改安全设置。

## 存档备份

退出游戏，在 Steam 中“浏览本地文件”：

- 右键游戏 `.app` →“显示包内容”，检查并复制 `.app/UserData`。
- 若外层游戏目录也存在 `UserData`，同样复制。
- 不同 Unity 打包布局还可能使用 `.app/Contents/UserData` 或 `.app/Contents/Resources/UserData`；已有这些目录时也应保留。不要用空目录覆盖它们。

安装和卸载时，脚本会复制以上实际存在的存档目录，校验副本哈希，并在操作后确认原存档没有变化。默认备份位置：

```text
~/Library/Application Support/MonsterRoadtripChinese/backups/<日期与随机后缀>/
```

其中 `UserDataCopies` 是存档副本，`previous` 是被替换或移除的 Mod 文件。所有备份只复制，不自动恢复进度。插件启动时还会根据 Unity 的实际 `Application.dataPath` 查找存档，在 `BepInEx/save-backups` 中保留 XML 快照。

## 卸载与升级

退出游戏，双击同包中的 `uninstall.command`，选择原游戏目录。或运行：

```bash
/bin/bash "/解压目录/uninstall.command" "/游戏目录"
```

卸载后，在 Steam 中删除本汉化那一行启动选项。存档、配置和备份保留；原先已有加载器或另有 Mod 时，保留共享加载器。文件内容发生改变时先停止，避免删除自行修改的内容。升级先卸载旧包，再安装新版；不自动覆盖其他版本的加载器。

## 兼容性与反馈

加载器为 BepInEx 5.4.23.5 的独立 macOS 版本，附带本项目的 Mono 布局修正。启动脚本限定 x86_64，并通过绝对路径定位 Doorstop。安装前检查 Mach-O 架构、Mono 程序集和所需接口名称；这些检查只能排除明显不兼容版本，不能代替真机测试。

反馈请提供 Mac 型号、macOS 版本、Intel／Apple Silicon、游戏版本、终端错误及 `BepInEx/LogOutput.log`。安装未通过检查时，不要手动强行覆盖加载器。

开发依据：[BepInEx Steam 启动说明](https://docs.bepinex.dev/master/articles/advanced/steam_interop.html?tabs=tabid-1)、[官方 macOS 加载器](https://github.com/BepInEx/BepInEx/releases/tag/v5.4.23.5)、[原生 arm64 的上游问题](https://github.com/BepInEx/BepInEx/issues/1404)、[Unity 的 Mac dataPath 定义](https://docs.unity3d.com/2021.3/Documentation/ScriptReference/Application-dataPath.html)。
