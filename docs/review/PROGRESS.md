# 全量汉化审校进度

状态：进行中。目标是对照英文检查全部 30,255 条文本；准确、自然的已有译文保留。

当前对照审校 4,149 条：保留 1,004 条，修正误译 2,867 条，润色表达 253 条，待确认 25 条。
其中 4,124 条已完成语言审校，26,106 条尚未逐句审校。语言审校不等于实机验证，
本轮没有将文本标记为 `ingame-ok`。

## 已覆盖范围

- 全部序章、教程、尾声与无事件兜底文本。
- 全部地点开场旁白、扭蛋商店台词和失败结局（包括单人、多人变体）。
- `cscottgrandma` 完整事件。
- `kaijudate_stage1`、`kaijudate_stage2`、`kaijudate_stage3` 完整事件与所有选项结果。
- 休息站、挑战提示、游戏结果及一部分相关系统提示。
- 全部系统工作表 2,871 条：主菜单、继续游戏、设置、角色选择、贴纸工坊、联机大厅、
  搭车客效果、地点名称与广告语、物品、目的地解锁、画廊标题、成就、草图、制作人员、
  暂停菜单、联机与存档错误、游戏内 Mod 管理。与其他批次重复的条目不重复计数。
  制作人员名单按段核对职务与配音角色；与英文完全一致的原始署名保留，不猜译用户名。
- 波莉的 8 段闲聊：`cpollycooking`、`cpollyghosts`、`cpollyapt`、`cpollychess`、
  `cpollytoiletwine`、`cpollyliterature`、`cpollyafterparty`、`cpollypartyetiquette`。
- 斯科特的另 8 段闲聊：`cscottastronomy`、`cscottapt`、`cscottmuscles`、`cscottjogging`、
  `cscottcheerethics`、`cscottsnacks`、`cscottteam`、`cscottchasingcars`。

每条英文、旧译文、新译文和审校决定见 `pass-001.csv` 至 `pass-015.csv`。
具体计数见 `progress.json`。`KEEP` 表示逐句审过并保留；`FIX` 表示修正含义或术语；
`POLISH` 表示改善语气与表达；`REVIEW` 表示仍有引用或语境需要核实。

## 待确认

- `english_events_standard:L495`：原文紧接着说明是歌词。本轮保留夜色与引路星的意象，
  修正字面译文；歌曲出处、是否有用户认可的现成译法尚未核实，状态保持 `draft`。
- `english_metatexts:STK_TAB_CHS`：SP 的具体含义未确认，暂保留该缩写，不臆造全称。
- `english_metatexts:RMD_CAVES`：spelunking/speluncrown 的造词笑话暂译为“洞王”皇冠，待核对探洞事件语境。
- `english_metatexts:RMD_LANDMARK_HOLE`：hole/whole 双关暂保留温馨广告语的意思，中文双关仍待改进。
- `english_metatexts:ITM_TTL_BLADEBLADE`、`ITM_TTL_MOUTHSTUFF`、
  `english_metatexts:ITM_TTL_STRONGSTUFF`：名称本身不足以确认物品的具体形态，先保留旧译，待查关联事件或物品图像。
- `english_metatexts:GLR_ECK_WARBOARDPIECE`：暂译为“战争棋盘棋子”，需结合关联事件确认这个造词的具体含义。

- `GLR_ECK_CODROUTE`：暂保留西班牙语原题，需进一步处理舞曲文化与 cod 的双关。
- `GLR_ACH_TTL_FIRSTFULLDESTINATION`：暂译“目的地宝藏”；目的地与 National Treasure 的拼词仍待改进。
- `GLR_CHR_BATNISS`、`GLR_CHR_HYPPERION`：保留英文名或暂译描述，角色名中的戏仿与叠词待最终统一。
- `GLR_CHR_OLDPOLLY`、`GLR_CHR_OLDSCOTT`、`GLR_CHR_OLDSCOTT2`、`GLR_CHR_OLDSCOTT3`：
  暂按旧版设计标签翻译，需要配图排除角色年龄的含义。
- `GLR_SK_GALLERY_SKETCH_CHIBIS_Q`：原文是 Dessert Rave，邻近标题为 Desert Rave，
  暂保留“甜点狂欢”的字面含义，需确认是否是源文件笔误。
- `GLR_SK_GALLERY_SKETCH_WIDE_M`、`M1`、`M2`、`M3`：仅有草图标题，
  暂译“达米恩的爸爸们：人质草图”，需配图确认谁是人质。
- `GLR_VAR_ENDING_MVP_SLIME_CRYPTID_CONVENTION`：键指向 Doug，英文标题却写 Jacqueline。
- `GLR_VAR_IMAGE_BACKGROUND_LOCATION_DINER_DOOM_SPECIALCHAR_FAITH`：键指向 Faith，英文标题却写 Hazel。
- `GLR_VAR_IMAGE_PC_PUMPKIN_KITE_TOURNAMENT`、`GLR_VAR_IMAGE_PC_PUMPKIN_VILLAGE_ANIMALS`：
  原文用了 Pumpkin 而非 Jacqueline。以上四条按原文翻译，需要配图确认，未擅自更改键或原文。

继续审校时以日志中的 `row_id` 和决定为准。`apply_overrides.py` 会重置部分行的
`status`/`notes`，不能据此把待确认条目或原有人工覆盖条目当作已经完成本轮审校。

## 后续待审

| 文件 | 未逐句审校条目 |
|---|---:|
| english_metatexts.json | 0（另有 24 条待确认） |
| english_events_bubbles.txt | 918 |
| english_events_pitstop.txt | 5,400 |
| english_events_maingame.txt | 17,989 |
| english_events_endings.txt | 1,799 |

系统表已通读，后续按完整事件审校休息站、气泡、主线事件及结局，并回查疑难标题；不得把
自动格式扫描计入人工语言审校。未审条目可用审校日志中的 `row_id` 集合与翻译 CSV
比较得到，继续时应先读取已有修改，避免重复修改已确认译文。

## 本轮统一的工作译名

这些是本工程的工作译名，不宣称是官方中文译法。后续需要连同上下文逐条统一，
不应做不区分语境的全局替换。

| 英文 | 工作译名 |
|---|---|
| Prank Dares | 恶作剧挑战 |
| Prank Dollarz | 恶作剧币（与持久进度代币分开） |
| Prank Tokens | 恶作剧代币 |
| Exchange Events | 资源交换事件 |
| Quantities Events | 资源数量事件 |
| Incremental Events | 分阶段事件 |
| Deep Conversations | 深入对话 |
| Destination Layers | 目的地扩展内容 |
| Hitchhikers | 搭车客 |
| Chaotic Energy | 混沌能量 |
| Kaiju / Mecha | 巨兽 / 机甲 |
| Afterparty | 续摊派对（对白中可用“续摊”） |
| Scott Snacks / Toilet Wine | 斯科特零食 / 马桶酒 |
| Trinkets | 小物件 |
| Coven / Airpeople | 女巫团 / 羽族 |
| Horsesona / Soupsona | 马版人设 / 汤版人设 |
| Cryptid Prom / Cryptid Convention | 神秘生物舞会 / 神秘生物大会（按原文区分） |

`glossary.json` 补充了本批所用的乔伊、莫斯、霍普、芬恩等人名，以及人鱼王国、
元小屋、惊悚学院等工作译名。未逐句审校的文本尚未做全局替换；后续按语境逐条统一。
Veranotone、《The Magus》等没有确认中文名称的专有名称，暂保留英文原名。

## 第 005–015 批的修订重点

- 联机大厅按钮与连接状态：修正“职业”“脱口而出”“拥抱”等错误译法。
- 资源提示：明确“增减幅度”的含义，区分“持续一周”与“一周后”，不臆造资源变化的数量。
- 画廊标题：对疑难双关查事件上下文；例如“搞乔伊战队”同时保留攻击乔伊与性暗示。
- 波莉：保留她在幽灵身份、家人和文学话题中的认真语气；修复马桶酒长串引号和国际象棋术语误译。
- 斯科特：保留真诚、天真与偶尔的深刻；修正 royalty、teamleisure、snacc 等词的意思，保留铺垫与笑点。

- 画廊与成就：修正搭车客、简历、约会结局、角色模型等误译；统一长椅、草图、服装与设计术语。
- 制作人员：修复“叮叮叮当”“库伊宁电信”及重复“红外”等乱码；对无法可靠译名的真实署名恢复原名。
- 游戏内 Mod 管理：修正“发布 Mod”被译成“玻利维亚 摩德”、手柄断连被译成“主计长断线”等错误。

本轮新增审校 2,944 条：保留 767 条，修正误译 2,004 条，润色 149 条，待确认 24 条。

有意义的修订示例（完整对照保存在 CSV 日志中）：

| 旧译 | 新译 | 原因 |
|---|---|---|
| 说话 波莉: 后缔约方 | 和波莉聊聊：续摊派对 | afterparty 被当成了外交用语 |
| 你得到了所有的好结局。你赢过吗？ | 你解锁了所有好结局。赢这么多次，你都不腻吗？ | 修复反向含义，保留调侃 |
| 达米恩深层对话:重现 | 达米恩的深入对话：简历 | resume 在此指简历 |
| 主计长已经断线了！ | 手柄已断开连接！ | controller 在此指游戏手柄 |

六项资源正文采用风格指南的热度、魔力、头脑、金钱、灵魂、体力。`STA_*`
解析器标识继续保留英文。

## 验证与交付状态

全部 CSV 的行数、稳定 ID、英文原文和非翻译字段与修改前一致。人工覆盖译文已同步，
不会被下一次构建回退。占位符检查和运行时事件控制字段检查通过。

本轮成果写入本地翻译源文件，并生成 `build/package` 的运行时译文。
当前已安装游戏、GitHub Release 与 `dist` 中的 v0.3.2 压缩包仍是原发行版本。
