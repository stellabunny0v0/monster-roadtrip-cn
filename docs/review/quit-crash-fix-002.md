# 退出崩溃：Mono 程序集结构兼容补丁

2026-10-31。已在隔离副本验证并安装 `mono-layout-1`；汉化插件仍为 v0.3.6。本次不新增语言审校覆盖，不改退出回调和存档读写逻辑。

## 根因与处理

本机副本对照显示：禁用加载器时正常退出；只加载 BepInEx、零插件时也出现 `0xC0000005`。中文全文、姓名补丁并非复现所必需。

进一步核对 [MonoMod issue 329](https://github.com/MonoMod/MonoMod/issues/329)、[修复 PR 330](https://github.com/MonoMod/MonoMod/pull/330) 与 [Unity 2021.3 Mono 原始结构](https://github.com/Unity-Technologies/mono/blob/unity-2021.3-mbe/mono/metadata/metadata-internals.h)：旧 MonoMod 的 `SetMonoCorlibInternal` 漏算 `MonoAssemblyName` 的三个名称标志。对这类 x86 布局，旧计算得出 0x4F，实际 `corlib_internal` 在 0x53；旧位置落在友元程序集列表指针内，退出释放列表时会访问错误地址。

为保留现有 BepInEx／Harmony API，采用上游检测与对齐算法的局部回移植：辅助库只计算正确偏移，不读写本机原生指针；原 MonoMod 保留自己的缓存、程序集指针取得和标志写入逻辑。仅在原方法的偏移计算后新增一条校正调用。未知布局检测失败时抛出错误，不猜测地址。原始依赖 SHA256 固定校验，不向不同版本盲目打补丁。

新增文件：`compat/MonoCorlibLayout.cs`、`tools/build-mono-compat.ps1`、`tools/install-mono-compat.ps1`。安装只替换 `BepInEx/core/MonoMod.Utils.dll` 并新增 `MonsterRoadtripMonoCompat.dll`。源加载器缓存不改。完整开源许可见 `compat/LICENSE-MonoMod.txt`。

## 验证

隔离副本使用同一游戏二进制、翻译和配置；只到主菜单及设置，不新建或继续游戏。测试环境未连接 Steam，因此这些结果证明本机 Mono／汉化加载与退出路径，不代表所有操作系统、Steam 联机功能或完整剧情都已实测。

| 条件 | 中文加载 | 退出结果 |
| --- | --- | --- |
| 无加载器 | 原版英文 | 0，正常 |
| 原加载器，零插件 | 原版英文 | 0xC0000005，崩溃 |
| 原加载器，完整汉化 | 正常 | 0xC0000005，崩溃 |
| 布局修复，完整汉化 | 正常 | 0，正常 |
| 布局修复，系统设置→返回→退出 | 正常，返回后 UI 完整 | 0，正常 |
| 最终待安装构建 | 正常 | 0，正常 |

离线检查覆盖 10 种结构／指针宽度组合及非法宽度拒绝。Cecil 对比全部 1,222 个方法体，除唯一偏移校正调用外的指令、分支、局部变量和异常区域均不变；只新增辅助库引用。辅助库编译 0 警告、0 错误。

Cecil／MethodBuilder 后端、关闭通用兼容补丁、替代初始化入口，以及旧版／新版依赖组合均曾在副本测试，但未同时满足正常汉化与正常退出，全部弃用。没有隐藏崩溃窗口、改 Unity 引擎、强制杀进程或跳过游戏退出清理。

## 安装与存档保护

本机安装已备份原依赖和 UserData；校验安装文件 SHA256，原游戏 11 个存档文件在整个测试和安装前后均未变化，全部配置及其他核心依赖未变化。本机姓名恢复规则保留。没有启动正式游戏、修改或回滚存档。

如需只撤销本次兼容补丁：关闭游戏，从本次 `backups/mono-layout-before-*/MonoMod.Utils.dll` 恢复原加载器文件，然后移除 `BepInEx/core/MonsterRoadtripMonoCompat.dll`。不要将测试副本或备份 UserData 覆盖回当前存档。

源码已推送，一键安装包已发布至 [v0.3.6-mono-layout-1](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/tag/v0.3.6-mono-layout-1)。原 v0.3.2 Release 不包含此修复。
