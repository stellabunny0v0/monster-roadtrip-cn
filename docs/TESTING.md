# 0.3.2 存档保护、稳定性与 Polly 夜间文本测试

## 启动

1. 正常通过 Steam 启动 `Monster Prom 3: Monster Roadtrip`。
2. 等待标题画面出现。
3. 不要先打开或编辑存档文件。

启动后检查 `BepInEx/save-backups/cn.monsterroadtrip.localization`，应出现新的 UTC 时间戳
目录，其中包含启动前的 XML/VDF 副本和 `SHA256SUMS.txt`。原 `UserData` 文件的哈希和
时间戳不应因备份动作本身发生变化。

## 标题画面

确认以下文字显示为中文且没有方框字：

- 开始游戏
- 设置
- 画廊
- 元商店
- 贴纸工坊
- 退出游戏

制作人员姓名、作品名和少量拟声词可能继续显示英文，这是当前机器初稿的预期行为。

## 设置画面

1. 打开“设置”。
2. 不要切换语言；游戏内部语言状态会保留为英文，以绕过游戏未完成的中文设置流程。
3. 确认“音乐”“音效”“语音”“窗口模式”等文字为中文。
4. 修改一次音量，然后返回标题画面。
5. 确认菜单 UI 仍存在、没有 Unity 报错，也没有弹出 `Streamer Attention`。

## 序章

1. 开始一局新游戏。
2. 完成玩家和路线设置，进入教程或序章。
3. 连续阅读至少十个对话框，确认正文显示中文。
4. 检查玩家名等运行时变量是否正常替换，没有显示 `%CURRENTPLAYERNAME%` 一类原始变量。
5. 检查换行、字号、中文标点、文字框边界和逐字显示效果。
6. 若方便，继续到第一个路线事件，确认选项和结果文本也显示中文。

## 夜间 Polly 对话

触发 Polly 的夜间闲聊时，确认口语自然，不再出现“波莉=======”、`瓳`、`糑`、
“野生波莉”“寒冷波莉”或“让我关闭”等机器翻译残留。对话中的玩家名必须正常替换。

## 日志

退出游戏后检查：

```text
<游戏根目录>\BepInEx\LogOutput.log
```

应出现：

```text
Non-invasive Chinese localization patches loaded from:
Loaded Chinese metatexts over the English language slot
Chinese font is ready:
```

日志中不得出现：

```text
FAILURE LOADING EVENTS
Provided event files contains
Known Stat
```

若启动失败，请保留该日志，不要反复安装其他加载器。

