# 《Monster Roadtrip》简体中文本地化风格指南

统一使用 `$monster-prom-series-zh`，已合并原 Roadtrip 审校 skill。
本页只补充项目的 UI 和资源用语，不重复加载系列通用规则。

- 人名按需查 [系列词表](series-reference/glossary.json)；[人名表](series-reference/names.md) 是同一资料的阅读版，二选一即可。
- 人物口吻只查 [人物指南](series-reference/voice-and-style.md) 的相关角色与例句。
- 文件编辑、覆盖同步、审校记录及技术校验统一见 [Roadtrip 工作流](series-reference/roadtrip.md)。已在 skill 中读过此页时不用再读副本。

本作的总体语气像熟人边旅行边互相吐槽；资源结算和 UI 以功能清晰、称名稳定为先。

## 常用术语

| 英文 | 显示译名 | 说明 |
|---|---|---|
| Hype | 热度 | `STA_HYPE` 的数据值必须保留 `Hype`，否则事件解析失败 |
| Magic | 魔力 | `STA_MAGIC` 的数据值必须保留 `Magic` |
| Mind | 头脑 | `STA_MIND` 的数据值必须保留 `Mind` |
| Money | 金钱 | `STA_MONEY` 的数据值必须保留 `Money` |
| Soul | 灵魂 | `STA_SOUL` 的数据值必须保留 `Soul` |
| Stamina | 体力 | `STA_STAMINA` 的数据值必须保留 `Stamina` |
| loading | 加载中…… | 不按动词 `love` 的含义处理 |
| on / off | 开启 / 关闭 | 用于设置开关 |
| turn someone off | 让人下头 / 让人没感觉 | 结合性暗示和上下文处理 |
| chill | 放松 / 歇会儿 / 安静待着 | 不译成“寒冷” |
| vibe | 兴致 / 气氛 / 感觉 | 根据动作和笑点选词 |

## 属性结算协议（不可按普通显示文字处理）

事件正文里的 `+N2 HYPE`、`-N2 STAMINA`、`+3 MIND` 是可执行结算标记；`N` 代表随周数／难度等换算的因子，不能删改或当成最终数字。`+XX PRANK DOLLARZ` 同样触发奖励。

CSV 可保留自然的中文显示词，但必须保持“正负号＋N（若有）＋数字＋属性名”完整成组，且各组先后顺序与原文一致。构建器将其恢复为原版英文结算标识，并处理中文相邻文字的 .NET 单词边界。构建后用与游戏一致的正则和枚举解析校验，不能仅检查数字或 CSV 控制列。

`STA_*` 数据值继续保留英文。右上角属性名在 StatWidget 显示组件本地化；对白中的彩色增减提示在原游戏 ConvertTextTags 完成结算后才转中文。不得在结算之前全局替换 HYPE／MIND 等词。

## 地点与姓名显示约定

所有 RML_* 地点和 DTT_* 目的地标题都应有中文显示名，包含 EOTR 变体；对照 translation/location_names_zh.json 校验，不能只核对普通地点。The Dinest 使用工作译名“至臻餐厅”，Simon Soups 餐馆为“西蒙汤馆”，音乐节 Veranotone 为“维拉诺顿”（目的地标题“维拉诺顿音乐节”）。这些不是官方旧译。Simon Soups 指机械角色时仍为“西蒙·汤”。

玩家自定义姓名不能被默认角色名替换。原版 ASCII XML 写入会丢失中文；由限定在玩家 Name 元素的数字实体写入保护解决，不改变存档布局、ID 或加密。已经丢成问号时无法凭空恢复；仅在本机明确配置、玩家 ID／角色 ID／损坏值全部匹配时恢复原名，正常姓名保持原样。不得自动重写旧存档。

## 主角选择界面的颜色称呼

按用户要求，PLY_ALT_BLUE/GREEN/RED/YELLOW/CINNAMON/ZOE/PUMPKIN/SLIME 分别使用“蓝／绿／红／黄／肉桂／紫／橙／绿松石”，不加“色”。此规则只作用于角色选择的颜色别称，不全局删改正文颜色词，不修改 PLY_NAM_* 的人名或玩家自定义姓名。
