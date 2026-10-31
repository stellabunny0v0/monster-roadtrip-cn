# v0.3.6：角色颜色称呼与退出崩溃诊断

2026-10-30。角色选择界面按用户要求去掉颜色称呼的“色”：蓝、绿、红、黄、肉桂、紫、橙、绿松石。仅改 8 个 PLY_ALT_* 显示项；人名、自定义姓名、正文颜色描述和已有姓名恢复配置不变。定点记录见 user-character-label-fixes-001.csv，不新增整句审校覆盖。

## 退出问题的本机证据

最近一次 v0.3.5 的 Unity Player.log 在退出时依次记录 GeneralManager OnApplicationQuit、Analytics RegisterSessionTime、Application Exit Detected，然后出现 Crash!!!。原生堆栈包括 RtlFreeHeap、mono_breakpoint_clean_code、mono_domain_free、mono_jit_cleanup。Unity 的 Crashes 目录也有对应本次退出时间的 crash.dmp 和 Player.log。

因此这是退出阶段的真实崩溃，不是普通游戏加载提示。BepInEx/LogOutput.log 没有记录这次崩溃，单查插件日志不足以认定退出正常。现有证据定位到 Unity/Mono 清理阶段，未能定位到某个汉化补丁，也没有证明是存档损坏。

BepInEx 官方仓库的 [issue 398](https://github.com/BepInEx/BepInEx/issues/398) 记录了其他 Unity 游戏在退出时同样落于 mono_domain_free / mono_jit_cleanup 的情况，有报告称即使移除插件仍会发生。这是相似性线索，不是本机根因或解决方案的证明；不能直接套用其他游戏的结论。更早的 [issue 139](https://github.com/BepInEx/BepInEx/issues/139) 涉及另一类退出/控制台问题；本机控制台本来就是关闭状态，不能据此认定切换控制台即可修复。

## 当前处理与边界

本次 v0.3.6 没有修改退出代码、BepInEx 核心、Harmony 后端、Doorstop、崩溃处理器或系统设置；也没有用强制结束进程掩盖错误。退出崩溃仍记未解决。完整原生日志保留在用户本机，仓库仅记录脱敏的诊断结论；相关行摘要放在被忽略的 analysis/quit-crash-evidence-001.txt，未提交完整系统模块／个人路径日志。

如继续定位，下一步是受控对照：只进入主菜单、不新建游戏、不读取继续存档，比较原版无加载器、仅加载器、加载汉化三种情况下正常点击退出的结果，每次记录 Player.log 和进程退出码，并在测试前备份整个 UserData。需要暂时切换加载器或插件时应保留可恢复副本，不能删除配置或存档。本次没有做这些切换或启动游戏，不能声称已完成对照。

## 验证与安装

译文表、运行时结构和属性结算协议校验通过；26 项 Python 测试及既有属性／动词／中文姓名 C# 回归通过，实际姓名写入 IL 核查仍通过。插件 Release 编译 0 警告、0 错误。

已备份旧插件并安装 v0.3.6，14 个文件哈希核对一致。安装前后 11 个 UserData 文件内容不变，原本机姓名恢复规则保留。角色选择显示仍需重启实机查看；退出崩溃没有标记为修复或 ingame-ok。


## 后续处理

2026-10-31 已完成受控对照及定点修复；当前状态与安装证据见 [quit-crash-fix-002.md](quit-crash-fix-002.md)。本页前述“未修复”为 v0.3.6 初次诊断时的历史状态。
