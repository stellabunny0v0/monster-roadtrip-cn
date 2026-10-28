# PENDING 原 109 条审校记录

审校日期：2026-10-22。范围固定为本轮开始时 PENDING.md 的 109 个唯一 row_id；未增加首次覆盖计数。

**56 条 KEEP、25 条 FIX、28 条 POLISH，语言待裁决项 0。** KEEP 表示 CSV 的中文 target 保持原样；其中有些条目仍需要本轮新增的运行时展开适配。另有 59 条动词变量完成按行适配，源码变量不变。

已连读相应完整事件的铺垫、选项和结果；画廊标题同时核查本地图片、角色表及分类代码。对英语独有的谐音，采用可读的中文补偿，或保留已有准确译文并说明取舍，不以缺少一一对应谐音自动认定错译。

校验：翻译表校验通过；事件控制字段校验通过；15 项 Python 测试通过；实际 C# 加载函数验证 59 条、11 个事件文件通过；插件 Release 编译 0 警告、0 错误；本批姓名扫描 0 候选。唯一空译文是原文同为空的隐藏成就描述。

**未安装、未启动游戏验收，未使用 ingame-ok。** 59 条的程序适配与静态／离线验证不代表实机已验证。

## 关键依据与实现

- Blade-Blade：查看 items_assets_all.bundle 的 item_bladeblade，为装刀片的陀螺；Mouth Stuff 的 item_mouthstuff 为一碗食物。The Strong Stuff 未能确认具体物品，以“够劲的玩意儿”保留含糊指称，不凭猜测写死烈酒。
- Chibi SP：本地反编译 StickerImageData.GetStickerImageType 将 >>>STICKERCHIBISP 映射到 StickerChibiSpecial。
- Old Polly／Old Scott 系列：完整 glitchspookyacademy 对话和 oldpolly、oldscott、oldscott2/3/4/5 图标显示设计逐级退化，保留旧版，不译老年。
- Dessert Rave：查看 gallery_sketch_chibis_q.png，图中舞台、饮料、舞者与沙漠派对吻合；标题拼写按场景修正。
- Damien Dads Hostage：查看 gallery_sketch_wide_m1/m2/m3.png，确为两位父亲被天使挟持；原译保留。
- Source 内部标签冲突：Jacqueline／Hazel／Pumpkin 按可见英文与角色资料判断，不以 SLIME／FAITH 等内部键擅改可见标题。
- 电车难题 L15128：两侧文本分别写明改道杀一救五、杀一还是杀五，足以判断 sparing 笔误；保留已按语境修正的译文。
- 火星塔罗 L22114：选项及整条分支均为富豪毁坏地球后移民火星，纠正 inhabitable 导致的反向译义。

本地图片仅用于核对，未将游戏图片、反编译代码或游戏资源加入 Git 提交。

运行时：translation/runtime_verb_overrides_zh.json 为逐行逐变量的编辑表。构建生成 schinese_verb_overrides.tsv，含行号、预期完整中文与展开文本。插件只在读到中文表后，核对行号及整句完全一致，再替换 TSV 第四列。失配会记录错误并保留原表，不套用旧翻译。人称、姓名、资源结算及控制列仍由游戏处理。

同一变量不能全局替换：IS／S_RE 可为空或“是”；HAS_HAVE 在体毛句是“长着”，在完成体句为空；DOESN’T_DON’T 必须保留否定；HAS_HAD 虽为原文异常形式，扑克上下文明确译“有”。

## 逐条裁决

### 1. english_events_standard:L495 — KEEP

事件：`standard_manor_gothic`。

英文：
~~~~text
But... in the velvet darkness of the blackest night, burning bright, there's a guiding star, no matter what or who you are...
~~~~

审校前：
~~~~text
不过……最漆黑的夜里，天鹅绒般的黑暗中，仍有一颗明亮的引路星，不论你是谁、是什么……
~~~~

审校后（翻译源表）：
~~~~text
不过……最漆黑的夜里，天鹅绒般的黑暗中，仍有一颗明亮的引路星，不论你是谁、是什么……
~~~~

理由：完整庄园开场明确下一句为歌词提示；引路星、夜色及不论身份均已保留，不强求套用未知的歌曲旧译。

### 2. english_metatexts:ITM_TTL_BLADEBLADE — FIX

事件：`metatext`。

英文：
~~~~text
The Dangerous Blade-Blade
~~~~

审校前：
~~~~text
危险的刀锋-布莱德
~~~~

审校后（翻译源表）：
~~~~text
危险的刀锋陀螺
~~~~

理由：本地 item_bladeblade 图片为带发射器、绑刀片的陀螺，非人物 Blade；保留危险玩具的戏仿。

### 3. english_metatexts:ITM_TTL_MOUTHSTUFF — FIX

事件：`metatext`。

英文：
~~~~text
Mouth Stuff
~~~~

审校前：
~~~~text
嘴巴相关的玩意儿
~~~~

审校后（翻译源表）：
~~~~text
往嘴里塞的玩意儿
~~~~

理由：本地 item_mouthstuff 图片是一碗食物；物品增加体力，mouth stuff 是含糊称呼吃的东西。

### 4. english_metatexts:ITM_TTL_STRONGSTUFF — FIX

事件：`metatext`。

英文：
~~~~text
The Strong Stuff
~~~~

审校前：
~~~~text
强壮的东西
~~~~

审校后（翻译源表）：
~~~~text
够劲的玩意儿
~~~~

理由：完整文本与物品资源未提供可确认的酒类对应；用够劲保留 strong stuff 的效力含义，不擅自指定烈酒，也不误作肌肉强壮。

### 5. english_metatexts:RMD_CAVES — KEEP

事件：`metatext`。

英文：
~~~~text
Someone said spelunking? Be sure to bring your speluncrown!
~~~~

审校前：
~~~~text
要去探洞？别忘了戴上你的“洞王”皇冠！
~~~~

审校后（翻译源表）：
~~~~text
要去探洞？别忘了戴上你的“洞王”皇冠！
~~~~

理由：洞穴开场与探洞活动吻合；spelunking 拆出 king 后造 speluncrown，洞王／皇冠已补偿王冠笑点。

### 6. english_metatexts:RMD_LANDMARK_HOLE — KEEP

事件：`metatext`。

英文：
~~~~text
It's got a "hole" lotta heart!
~~~~

审校前：
~~~~text
一个洞，满满的心意！
~~~~

审校后（翻译源表）：
~~~~text
一个洞，满满的心意！
~~~~

理由：地图大洞的宣传语；洞和满满的心意已兼顾 hole 与 whole lotta heart 的语义，不强造中文谐音。

### 7. english_metatexts:STK_TAB_CHS — FIX

事件：`metatext`。

英文：
~~~~text
Chibi SP
~~~~

审校前：
~~~~text
Q版 SP
~~~~

审校后（翻译源表）：
~~~~text
Q版特殊角色
~~~~

理由：StickerImageData.GetStickerImageType 将 STICKERCHIBISP 映射为 StickerChibiSpecial，可确认 SP 是特殊类别。

### 8. english_metatexts:GLR_ACH_TTL_FIRSTFULLDESTINATION — KEEP

事件：`metatext`。

英文：
~~~~text
Desti-national Treasure
~~~~

审校前：
~~~~text
目的地宝藏
~~~~

审校后（翻译源表）：
~~~~text
目的地宝藏
~~~~

理由：同组描述明确提及 Nicolas Cage；目的地宝藏保留目的地和寻宝电影意象，现有成就标题简洁可用，英语拼词不强行直搬。

### 9. english_metatexts:GLR_ECK_CODROUTE — FIX

事件：`metatext`。

英文：
~~~~text
La Ruta del Bakalao
~~~~

审校前：
~~~~text
La Ruta del Bakalao
~~~~

审校后（翻译源表）：
~~~~text
鳕鱼之路
~~~~

理由：完整 codroute 事件称 Cod Route 并解释西班牙夜店巡游；与正文统一。

### 10. english_metatexts:GLR_CHR_BATNISS — FIX

事件：`metatext`。

英文：
~~~~text
Batniss
~~~~

审校前：
~~~~text
Batniss
~~~~

审校后（翻译源表）：
~~~~text
巴特尼斯
~~~~

理由：完整 overkill／choosebattleally 事件已有巴特尼斯工作译名；画廊统一，非宣称旧作官方名。

### 11. english_metatexts:GLR_CHR_OLDPOLLY — KEEP

事件：`metatext`。

英文：
~~~~text
Old Polly
~~~~

审校前：
~~~~text
旧版波莉
~~~~

审校后（翻译源表）：
~~~~text
旧版波莉
~~~~

理由：glitchspookyacademy 明确回到过去的画风，后续逐步退化为更早设计及草图；旧版是设计版本而非老年。

### 12. english_metatexts:GLR_CHR_OLDSCOTT — KEEP

事件：`metatext`。

英文：
~~~~text
Old Scott
~~~~

审校前：
~~~~text
旧版斯科特
~~~~

审校后（翻译源表）：
~~~~text
旧版斯科特
~~~~

理由：glitchspookyacademy 明确回到过去的画风，后续逐步退化为更早设计及草图；旧版是设计版本而非老年。

### 13. english_metatexts:GLR_CHR_OLDSCOTT2 — KEEP

事件：`metatext`。

英文：
~~~~text
Older Scott
~~~~

审校前：
~~~~text
更旧版斯科特
~~~~

审校后（翻译源表）：
~~~~text
更旧版斯科特
~~~~

理由：glitchspookyacademy 明确回到过去的画风，后续逐步退化为更早设计及草图；旧版是设计版本而非老年。

### 14. english_metatexts:GLR_CHR_OLDSCOTT3 — KEEP

事件：`metatext`。

英文：
~~~~text
Oldest Scott
~~~~

审校前：
~~~~text
最旧版斯科特
~~~~

审校后（翻译源表）：
~~~~text
最旧版斯科特
~~~~

理由：glitchspookyacademy 明确回到过去的画风，后续逐步退化为更早设计及草图；旧版是设计版本而非老年。

### 15. english_metatexts:GLR_SK_GALLERY_SKETCH_CHIBIS_Q — FIX

事件：`metatext`。

英文：
~~~~text
Location Chibis - Dessert Rave Sketch
~~~~

审校前：
~~~~text
地点 Q版草图 - 甜点狂欢
~~~~

审校后（翻译源表）：
~~~~text
地点 Q版草图 - 沙漠锐舞派对
~~~~

理由：已查看 gallery_sketch_chibis_q：舞台、酒瓶及跳舞人物，关联沙漠锐舞地点；Dessert 为此标题的拼写笔误。

### 16. english_metatexts:GLR_SK_GALLERY_SKETCH_WIDE_M — KEEP

事件：`metatext`。

英文：
~~~~text
Damien Dads Hostage Sketches
~~~~

审校前：
~~~~text
德魔的爸爸们：人质草图
~~~~

审校后（翻译源表）：
~~~~text
德魔的爸爸们：人质草图
~~~~

理由：已查看 gallery_sketch_wide_m1/m2/m3：德魔的两位父亲被天使挟持并捆绑；现有人质草图标题准确。

### 17. english_metatexts:GLR_SK_GALLERY_SKETCH_WIDE_M1 — KEEP

事件：`metatext`。

英文：
~~~~text
Damien Dads Hostage Sketches - 1
~~~~

审校前：
~~~~text
德魔的爸爸们：人质草图 - 1
~~~~

审校后（翻译源表）：
~~~~text
德魔的爸爸们：人质草图 - 1
~~~~

理由：已查看 gallery_sketch_wide_m1/m2/m3：德魔的两位父亲被天使挟持并捆绑；现有人质草图标题准确。

### 18. english_metatexts:GLR_SK_GALLERY_SKETCH_WIDE_M2 — KEEP

事件：`metatext`。

英文：
~~~~text
Damien Dads Hostage Sketches - 2
~~~~

审校前：
~~~~text
德魔的爸爸们：人质草图 - 2
~~~~

审校后（翻译源表）：
~~~~text
德魔的爸爸们：人质草图 - 2
~~~~

理由：已查看 gallery_sketch_wide_m1/m2/m3：德魔的两位父亲被天使挟持并捆绑；现有人质草图标题准确。

### 19. english_metatexts:GLR_SK_GALLERY_SKETCH_WIDE_M3 — KEEP

事件：`metatext`。

英文：
~~~~text
Damien Dads Hostage Sketches - 3
~~~~

审校前：
~~~~text
德魔的爸爸们：人质草图 - 3
~~~~

审校后（翻译源表）：
~~~~text
德魔的爸爸们：人质草图 - 3
~~~~

理由：已查看 gallery_sketch_wide_m1/m2/m3：德魔的两位父亲被天使挟持并捆绑；现有人质草图标题准确。

### 20. english_metatexts:GLR_VAR_ENDING_MVP_SLIME_CRYPTID_CONVENTION — KEEP

事件：`metatext`。

英文：
~~~~text
MVP Ending Jacqueline - Cryptid Convention
~~~~

审校前：
~~~~text
MVP 结局 - 杰奎琳 - 神秘生物大会
~~~~

审校后（翻译源表）：
~~~~text
MVP 结局 - 杰奎琳 - 神秘生物大会
~~~~

理由：正文及角色表确认 Jacqueline＝杰奎琳；画廊可见 source 优先于含 SLIME 的内部键，不据内部键改成人名斯图。

### 21. english_metatexts:GLR_VAR_IMAGE_BACKGROUND_LOCATION_DINER_DOOM_SPECIALCHAR_FAITH — KEEP

事件：`metatext`。

英文：
~~~~text
Doom's Diner Chibis - Hazel
~~~~

审校前：
~~~~text
末日餐厅 Q版 - 海泽尔
~~~~

审校后（翻译源表）：
~~~~text
末日餐厅 Q版 - 海泽尔
~~~~

理由：角色表 PLY_NAM_CINNAMON 确认 Hazel＝海泽尔；FAITH 是此画廊的内部键，不覆盖可见标题。

### 22. english_metatexts:GLR_VAR_IMAGE_PC_PUMPKIN_KITE_TOURNAMENT — KEEP

事件：`metatext`。

英文：
~~~~text
Kite Tournament Chibis - Pumpkin
~~~~

审校前：
~~~~text
风筝锦标赛 Q版 - 南瓜
~~~~

审校后（翻译源表）：
~~~~text
风筝锦标赛 Q版 - 南瓜
~~~~

理由：source 此处确实使用 Pumpkin 作为角色类别标签；保留南瓜，不一律改成杰奎琳。

### 23. english_metatexts:GLR_VAR_IMAGE_PC_PUMPKIN_VILLAGE_ANIMALS — KEEP

事件：`metatext`。

英文：
~~~~text
Adorable Village Chibis - Pumpkin
~~~~

审校前：
~~~~text
可爱村庄 Q版 - 南瓜
~~~~

审校后（翻译源表）：
~~~~text
可爱村庄 Q版 - 南瓜
~~~~

理由：source 此处确实使用 Pumpkin 作为角色类别标签；保留南瓜，不一律改成杰奎琳。

### 24. english_events_pitstop:L2884 — KEEP

事件：`cdamienhell`。

英文：
~~~~text
...sapphisticated?
~~~~

审校前：
~~~~text
……蚊雅一点？
~~~~

审校后（翻译源表）：
~~~~text
……蚊雅一点？
~~~~

理由：德魔刚说想学李姆讲究措辞却说不出 sophisticated；蚊雅保留文雅的故意错字，不按 sapphic 另造性向信息。

### 25. english_events_pitstop:L2896 — KEEP

事件：`cdamienhell`。

英文：
~~~~text
ANYHOW, bottom line (hehe, bottom):
~~~~

审校前：
~~~~text
总之，下个“腚论”（嘿嘿，屁股）：
~~~~

审校后（翻译源表）：
~~~~text
总之，下个“腚论”（嘿嘿，屁股）：
~~~~

理由：上下文反复开屁股玩笑；腚论／屁股准确补偿 bottom line／bottom。

### 26. english_events_pitstop:L3395 — KEEP

事件：`cmosscryptids`。

英文：
~~~~text
It is light and momentous, but still quite dangerous.
~~~~

审校前：
~~~~text
这种扰动虽轻微，影响却不小，而且仍相当危险。
~~~~

审校后（翻译源表）：
~~~~text
这种扰动虽轻微，影响却不小，而且仍相当危险。
~~~~

理由：紧接帷幕裂隙与被人类捕获的风险；现译符合 light 与 momentous 的字面义。没有足够依据把 momentous 擅改为 momentary。

### 27. english_events_pitstop:L3460 — POLISH

事件：`cmossPhD`。

英文：
~~~~text
A mouthful of hot gossip.
~~~~

审校前：
~~~~text
绕来绕去，全是满嘴的劲爆八卦。
~~~~

审校后（翻译源表）：
~~~~text
满嘴都是劲爆八卦嘛。
~~~~

理由：承接玩家的绕口评价，以满嘴延续 mouthful 的口部意象，删掉不自然的绕来绕去。

### 28. english_events_pitstop:L148 — KEEP

事件：`pitstop_car_18`。

英文：
~~~~text
You approach a leather-clad motorcyclist smoking a cigarette and say, "Why did the bike fall over? Because it was TWO TIRED!"
~~~~

审校前：
~~~~text
你走向一位穿皮衣、正抽烟的摩托车手，说：“自行车为什么倒了？因为它两个轮胎都‘胎’累了！”
~~~~

审校后（翻译源表）：
~~~~text
你走向一位穿皮衣、正抽烟的摩托车手，说：“自行车为什么倒了？因为它两个轮胎都‘胎’累了！”
~~~~

理由：完整挑战为向陌生骑手讲冷笑话；两个轮胎／胎累已呈现 two tires／too tired，保留已有可理解的冷笑话。

### 29. english_events_pitstop:L159 — KEEP

事件：`pitstop_car_19`。

英文：
~~~~text
But what should you graffiti? "%CURRENTPLAYERNAME% wuz here"? "Naruto x Garfield 5ever"? The Cool S?
~~~~

审校前：
~~~~text
涂什么呢？“%CURRENTPLAYERNAME%到此一游”？“鸣人×加菲猫，永远再加一！”？还是那个酷酷的S？
~~~~

审校后（翻译源表）：
~~~~text
涂什么呢？“%CURRENTPLAYERNAME%到此一游”？“鸣人×加菲猫，永远再加一！”？还是那个酷酷的S？
~~~~

理由：完整涂鸦情境；永远再加一已表达 5ever 比 4ever 多一的夸张，旧备注五生五世已过时。

### 30. english_events_bubbles:L354 — KEEP

事件：`bubble_going_space_station`。

英文：
~~~~text
Don't "rocket" 'til you try it, amirite?
~~~~

审校前：
~~~~text
没试过，别急着“炮”轰嘛，对不对？
~~~~

审校后（翻译源表）：
~~~~text
没试过，别急着“炮”轰嘛，对不对？
~~~~

理由：斯科特先喊火箭、后说没听懂；炮轰兼顾火箭意象与未经尝试便批评，已是可用的中文补偿。

### 31. english_events_bubbles:L909 — FIX

事件：`bubble_going_con2`。

英文：
~~~~text
I hope you like hanging around fans, Scott!
~~~~

审校前：
~~~~text
希望你喜欢跟一堆“fan”待在一起，斯科特！
~~~~

审校后（翻译源表）：
~~~~text
斯科特，希望你喜欢被粉丝们使劲“吹”！
~~~~

理由：后句斯科特回答喜欢新鲜空气；以粉丝吹捧的吹连接风，不再要求玩家认识英文 fan。

### 32. english_events_endings:L961 — FIX

事件：`ending_neutral_coop_1`。

英文：
~~~~text
Yes, you will do that! And the troupe's name will be "The Kitchen Sync"!
~~~~

审校前：
~~~~text
对，就这么办！舞团就叫“厨房同步团”（The Kitchen Sync）！
~~~~

审校后（翻译源表）：
~~~~text
对，就这么办！舞团就叫“厨房洗舞池”！
~~~~

理由：完整合作结局以同步成立舞团；洗舞池将厨房洗水池意象与舞蹈合成中文队名，替换无双关的中英重复标题。

### 33. english_events_endings:L978 — FIX

事件：`ending_neutral_coop_2`。

英文：
~~~~text
C'mon, come with your road trip team name. Not to confuse with your dance troupe name ("The Kitchen's Sync").
~~~~

审校前：
~~~~text
来，给这趟公路旅行的小队起个名。别跟舞团名字“厨房同步团”（The Kitchen's Sync）搞混了。
~~~~

审校后（翻译源表）：
~~~~text
来，给这趟公路旅行的小队起个名。别跟舞团名字“厨房洗舞池”搞混了。
~~~~

理由：与前一合作结局的同一舞团保持一致，保留旅行队名与舞团名的区别。

### 34. english_events_endings:L1081 — KEEP

事件：`ending_mvp_music_festival_red`。

英文：
~~~~text
"...%HESHE%%VERB_'S_'RE% very cool. Like, VERY VERY COOL."
~~~~

审校前：
~~~~text
“……%HESHE%%VERB_'S_'RE%太酷了。真的，酷得不得了。”
~~~~

审校后（翻译源表）：
~~~~text
“……%HESHE%%VERB_'S_'RE%太酷了。真的，酷得不得了。”
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
“……%HESHE%太酷了。真的，酷得不得了。”
~~~~

理由：吉他手被玩家的酷劲儿迷住；形容词谓语无需系词。

### 35. english_events_endings:L1082 — POLISH

事件：`ending_mvp_music_festival_red`。

英文：
~~~~text
"%HESHE% %VERB_IS_ARE% so cool that I just can't focus. It's like %HISHER% awesomeness is... blinding me."
~~~~

审校前：
~~~~text
“%HESHE% %VERB_IS_ARE%太酷了，酷得我没法集中精神。简直是%HISHER%酷劲儿……晃瞎了我的眼。”
~~~~

审校后（翻译源表）：
~~~~text
“%HESHE%%VERB_IS_ARE%太酷了，酷得我没法集中精神。简直是%HISHER%酷劲儿……晃瞎了我的眼。”
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
“%HESHE%太酷了，酷得我没法集中精神。简直是%HISHER%酷劲儿……晃瞎了我的眼。”
~~~~

理由：同段吉他手感叹；去掉英文语法占位周围的多余空格，保留 HISHER 自带的。

### 36. english_events_endings:L2168 — FIX

事件：`ending_date_polly1`。

英文：
~~~~text
I wondered, '%VERB_IS_ARE% %HESHE% going to reply? Will %HESHE% say yes?
~~~~

审校前：
~~~~text
我当时想：‘%HESHE%%VERB_IS_ARE%不是会回我消息？%HESHE%会答应吗？’
~~~~

审校后（翻译源表）：
~~~~text
我当时想：‘%HESHE%%VERB_IS_ARE%会回我消息吗？%HESHE%会答应吗？’
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
我当时想：‘%HESHE%会回我消息吗？%HESHE%会答应吗？’
~~~~

理由：波莉回忆等待短信的紧张，是会不会回复的疑问而非不是会的否定句；系词不进入中文。

### 37. english_events_endings:L2378 — KEEP

事件：`ending_date_miranda`。

英文：
~~~~text
And it occurred to me: %CURRENTPLAYERNAME% is silly and cute and %HESHE% %VERB_AMUSES_AMUSE% me, so maybe %HESHE% would be willing to assist me with that.
~~~~

审校前：
~~~~text
我突然想到，%CURRENTPLAYERNAME%傻乎乎的，又很可爱，%HESHE%还会%VERB_AMUSES_AMUSE%我。所以，也许%HESHE%愿意帮帮我。
~~~~

审校后（翻译源表）：
~~~~text
我突然想到，%CURRENTPLAYERNAME%傻乎乎的，又很可爱，%HESHE%还会%VERB_AMUSES_AMUSE%我。所以，也许%HESHE%愿意帮帮我。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
我突然想到，%CURRENTPLAYERNAME%傻乎乎的，又很可爱，%HESHE%还会逗乐我。所以，也许%HESHE%愿意帮帮我。
~~~~

理由：与弄臣和性爱的前后文一致；amuse 在此为逗乐，保留两次人称。

### 38. english_events_maingame:L365 — KEEP

事件：`evilmenu`。

英文：
~~~~text
Will the soup turn %CURRENTPLAYERNAME%'s nostrils inside out when %HESHE% %VERB_INHALES_INHALE% its delicious smell?!
~~~~

审校前：
~~~~text
%CURRENTPLAYERNAME%一%VERB_INHALES_INHALE%到它的香气，这汤就会把%HESHE%的鼻孔翻个面吗？！
~~~~

审校后（翻译源表）：
~~~~text
%CURRENTPLAYERNAME%一%VERB_INHALES_INHALE%到它的香气，这汤就会把%HESHE%的鼻孔翻个面吗？！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
%CURRENTPLAYERNAME%一闻到它的香气，这汤就会把%HESHE%的鼻孔翻个面吗？！
~~~~

理由：闻汤香引发鼻孔翻面的夸张；中文用闻到香气。

### 39. english_events_maingame:L413 — KEEP

事件：`findbooth`。

英文：
~~~~text
I like when %HESHE% %VERB_DOES_DO% the chanting part, though. It's sort of soothing!
~~~~

审校前：
~~~~text
不过，我挺喜欢听%HESHE%%VERB_DOES_DO%念咒那段。还挺舒心的！
~~~~

审校后（翻译源表）：
~~~~text
不过，我挺喜欢听%HESHE%%VERB_DOES_DO%念咒那段。还挺舒心的！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
不过，我挺喜欢听%HESHE%念咒那段。还挺舒心的！
~~~~

理由：do the chanting 已由念咒表达，不再追加做。

### 40. english_events_maingame:L415 — KEEP

事件：`findbooth`。

英文：
~~~~text
There %HESHE% %VERB_GOES_GO% again. I'm telling you: if you're not keeping all that blood, we could at least be doing way funnier things with it.
~~~~

审校前：
~~~~text
%HESHE%又%VERB_GOES_GO%开始了。我说啊，既然这些血你也不打算留着，咱们至少能拿来玩点更有意思的。
~~~~

审校后（翻译源表）：
~~~~text
%HESHE%又%VERB_GOES_GO%开始了。我说啊，既然这些血你也不打算留着，咱们至少能拿来玩点更有意思的。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
%HESHE%又开始了。我说啊，既然这些血你也不打算留着，咱们至少能拿来玩点更有意思的。
~~~~

理由：there goes again 已由又开始表达，不能再字译走。

### 41. english_events_maingame:L564 — KEEP

事件：`fetchpicnic`。

英文：
~~~~text
That's an obvious sign that %HESHE%%VERB_'S_'RE% saving %HISHER% energy to masturbate later.
~~~~

审校前：
~~~~text
这明显说明，%HESHE%%VERB_'S_'RE%在省着%HISHER%体力，留到晚点自慰。
~~~~

审校后（翻译源表）：
~~~~text
这明显说明，%HESHE%%VERB_'S_'RE%在省着%HISHER%体力，留到晚点自慰。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
这明显说明，%HESHE%在省着%HISHER%体力，留到晚点自慰。
~~~~

理由：进行体由在省着表达，HISHER 已带所有格。

### 42. english_events_maingame:L609 — POLISH

事件：`fetchpicnic`。

英文：
~~~~text
...%HESHE%%VERB_'S_'VE% had Scott's stick hidden in %HISHER% back pocket this whole time.
~~~~

审校前：
~~~~text
……%HESHE%%VERB_'S_'VE%一直把斯科特的棍子，藏在%HISHER%后裤袋里。
~~~~

审校后（翻译源表）：
~~~~text
……%HESHE%%VERB_'S_'VE%一直把斯科特的棍子藏在%HISHER%后裤袋里。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
……%HESHE%一直把斯科特的棍子藏在%HISHER%后裤袋里。
~~~~

理由：希望女巫揭穿棍子藏在后裤袋；去掉动宾之间的多余逗号，完成体不重复译。

### 43. english_events_maingame:L851 — KEEP

事件：`deathballs`。

英文：
~~~~text
Yup. %CURRENTPLAYERNAME% over here thinks %HESHE%%VERB_'S_'VE% got some big, brass 8-balls between %HISHER% legs!
~~~~

审校前：
~~~~text
没错。这位%CURRENTPLAYERNAME%觉得，%HESHE%%VERB_'S_'VE%在%HISHER%两腿之间，长了对硕大的黄铜8号球呢！
~~~~

审校后（翻译源表）：
~~~~text
没错。这位%CURRENTPLAYERNAME%觉得，%HESHE%%VERB_'S_'VE%在%HISHER%两腿之间，长了对硕大的黄铜8号球呢！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
没错。这位%CURRENTPLAYERNAME%觉得，%HESHE%在%HISHER%两腿之间，长了对硕大的黄铜8号球呢！
~~~~

理由：黄铜8号球兼指胆量、台球与睾丸；got 已由长了表达。

### 44. english_events_maingame:L1100 — KEEP

事件：`eulogy`。

英文：
~~~~text
But if %CURRENTPLAYERNAME% is really the deceased, why %VERB_DOES_DO% %HESHE% look like %CURRENTPLAYERNAME%?
~~~~

审校前：
~~~~text
可如果%CURRENTPLAYERNAME%真是死者，为什么%HESHE%%VERB_DOES_DO%还长得像%CURRENTPLAYERNAME%？
~~~~

审校后（翻译源表）：
~~~~text
可如果%CURRENTPLAYERNAME%真是死者，为什么%HESHE%%VERB_DOES_DO%还长得像%CURRENTPLAYERNAME%？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
可如果%CURRENTPLAYERNAME%真是死者，为什么%HESHE%还长得像%CURRENTPLAYERNAME%？
~~~~

理由：斯科特把玩家与死者的身份绕混；疑问助动词无需另译。

### 45. english_events_maingame:L1528 — FIX

事件：`wildwesthorsie`。

英文：
~~~~text
When they're covering the robbery on the news later, they call your crime outfit "Whinny and the Poo."
~~~~

审校前：
~~~~text
后来，新闻报道这场抢劫，把你们这个犯罪组合称为“马鸣与便便（Whinny and the Poo）”。
~~~~

审校后（翻译源表）：
~~~~text
后来，新闻报道这场抢劫，把你们这个犯罪组合称为“小马维尼与便便”。
~~~~

理由：前句明确马指挥抢劫、玩家吓出便便；小马维尼与便便保留马、排泄及 Winnie the Pooh 的戏仿。

### 46. english_events_maingame:L1536 — KEEP

事件：`wildwesthorsie`。

英文：
~~~~text
Nah, %HESHE%%VERB_'S_'RE% always making that face.
~~~~

审校前：
~~~~text
没有啊，%HESHE%%VERB_'S_'RE%一直就是这表情。
~~~~

审校后（翻译源表）：
~~~~text
没有啊，%HESHE%%VERB_'S_'RE%一直就是这表情。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
没有啊，%HESHE%一直就是这表情。
~~~~

理由：波莉把被马控制后的空洞表情当成常态；系词已由就是表达。

### 47. english_events_maingame:L2051 — KEEP

事件：`manypancakes`。

英文：
~~~~text
"That's true...," says another mom, "but don't you find it disturbing how much body hair %HESHE% %VERB_HAS_HAVE% at %HISHER% age?"
~~~~

审校前：
~~~~text
“是啊……”另一位妈妈说，“可%HESHE%在%HISHER%这个年纪，就%VERB_HAS_HAVE%那么多体毛，不觉得吓人吗？”
~~~~

审校后（翻译源表）：
~~~~text
“是啊……”另一位妈妈说，“可%HESHE%在%HISHER%这个年纪，就%VERB_HAS_HAVE%那么多体毛，不觉得吓人吗？”
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
“是啊……”另一位妈妈说，“可%HESHE%在%HISHER%这个年纪，就长着那么多体毛，不觉得吓人吗？”
~~~~

理由：婴幼儿比赛里的妈妈谈体毛；has 为长着，非完成时。

### 48. english_events_maingame:L2054 — POLISH

事件：`manypancakes`。

英文：
~~~~text
NOICE! How much money %VERB_DOES_DO% %HESHE% win?
~~~~

审校前：
~~~~text
漂亮！%HESHE%能赢%VERB_DOES_DO%多少奖金？
~~~~

审校后（翻译源表）：
~~~~text
漂亮！%HESHE%%VERB_DOES_DO%能赢多少奖金？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
漂亮！%HESHE%能赢多少奖金？
~~~~

理由：追问奖金；助动词不译，移回主语后的语法位置。

### 49. english_events_maingame:L2118 — KEEP

事件：`bestthechampion`。

英文：
~~~~text
But I'm sure %CURRENTPLAYERNAME% will do it! %HESHE%%VERB_'S_'RE% always doing weird challenges for our entertainment.
~~~~

审校前：
~~~~text
不过，%CURRENTPLAYERNAME%肯定会参加！%HESHE%%VERB_'S_'RE%老爱做些怪挑战，逗我们开心。
~~~~

审校后（翻译源表）：
~~~~text
不过，%CURRENTPLAYERNAME%肯定会参加！%HESHE%%VERB_'S_'RE%老爱做些怪挑战，逗我们开心。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
不过，%CURRENTPLAYERNAME%肯定会参加！%HESHE%老爱做些怪挑战，逗我们开心。
~~~~

理由：大餐挑战开场，老爱做怪挑战已完整传达原意。

### 50. english_events_maingame:L2142 — POLISH

事件：`bestthechampion`。

英文：
~~~~text
Meh, let %HIMHER% do what %HESHE% %VERB_WANTS_WANT%. I'm in no place to judge anyone for ingesting questionable stuff.
~~~~

审校前：
~~~~text
随便啦，让%HIMHER%做%HESHE%%VERB_WANTS_WANT%做的。我可没资格，批评别人乱吃东西。
~~~~

审校后（翻译源表）：
~~~~text
随便啦，让%HIMHER%做%HESHE%%VERB_WANTS_WANT%做的。我可没资格批评别人乱吃东西。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
随便啦，让%HIMHER%做%HESHE%想做的。我可没资格批评别人乱吃东西。
~~~~

理由：想做什么就做什么，保留波莉不评判乱吃东西的态度，删掉主谓之间的逗号。

### 51. english_events_maingame:L2207 — KEEP

事件：`pancakegift`。

英文：
~~~~text
The pizza girl brings you to her manager in the kitchen. He's wearing a pimp coat and a fedora with a pancake brim.
~~~~

审校前：
~~~~text
披萨女孩带你去厨房，见到了她的经理。他穿着皮条客大衣，头戴一顶用煎饼做帽檐的礼帽。
~~~~

审校后（翻译源表）：
~~~~text
披萨女孩带你去厨房，见到了她的经理。他穿着皮条客大衣，头戴一顶用煎饼做帽檐的礼帽。
~~~~

理由：整个事件服务员槽位均为 pizzagirl；wigshop 又明说她打二十多份工，煎饼餐厅不构成改掉披萨女孩称呼的依据。

### 52. english_events_maingame:L2208 — KEEP

事件：`pancakegift`。

英文：
~~~~text
"This is the new kid?" he asks the waitress. "You sure %HESHE%%VERB_'S_'VE% got what it takes to be a Pancake Lord?"
~~~~

审校前：
~~~~text
“就是这新人？”他问服务员，“你确定%HESHE%%VERB_'S_'VE%有当煎饼领主的本事？”
~~~~

审校后（翻译源表）：
~~~~text
“就是这新人？”他问服务员，“你确定%HESHE%%VERB_'S_'VE%有当煎饼领主的本事？”
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
“就是这新人？”他问服务员，“你确定%HESHE%有当煎饼领主的本事？”
~~~~

理由：经理问是否有本事，got 已由有表达。

### 53. english_events_maingame:L2728 — KEEP

事件：`stallfavors`。

英文：
~~~~text
You give %HIMHER% a wad of toilet paper, and %HESHE% %VERB_LEAVES_LEAVE% you alone... for about thirty seconds.
~~~~

审校前：
~~~~text
你递给%HIMHER%一团厕纸。%HESHE%%VERB_LEAVES_LEAVE%总算不再烦你……大概三十秒。
~~~~

审校后（翻译源表）：
~~~~text
你递给%HIMHER%一团厕纸。%HESHE%%VERB_LEAVES_LEAVE%总算不再烦你……大概三十秒。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
你递给%HIMHER%一团厕纸。%HESHE%总算不再烦你……大概三十秒。
~~~~

理由：leave alone 已由不再烦你表达；三十秒后继续索取的包袱保留。

### 54. english_events_maingame:L2738 — KEEP

事件：`stallfavors`。

英文：
~~~~text
You suggest "bellybutton." You also ask if %HESHE%%VERB_'S_'VE% got any other favors or "funny stories" for you before you get back to doing your business.
~~~~

审校前：
~~~~text
你给出“bellybutton”这个答案。接着问，你还没拉完，%HESHE%%VERB_'S_'VE%还有多少忙要帮，或者“好笑的故事”要讲？
~~~~

审校后（翻译源表）：
~~~~text
你给出“bellybutton”这个答案。接着问，你还没拉完，%HESHE%%VERB_'S_'VE%还有多少忙要帮，或者“好笑的故事”要讲？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
你给出“bellybutton”这个答案。接着问，你还没拉完，%HESHE%还有多少忙要帮，或者“好笑的故事”要讲？
~~~~

理由：上句是十一字母的 navel 填字题，bellybutton 必须保留英文；have got 已由还有表达。

### 55. english_events_maingame:L2776 — POLISH

事件：`stallfavors`。

英文：
~~~~text
You spend the whole afternoon piggybacking %MRMRS% Walters-Closseau around. %HESHE% %VERB_LETS_LET% you get back to your friends at the end of the day.
~~~~

审校前：
~~~~text
你整个下午，都背着沃尔特斯-克卢梭%MRMRS%四处转。直到傍晚，%HESHE%%VERB_LETS_LET%总算准你回朋友身边。
~~~~

审校后（翻译源表）：
~~~~text
你整个下午都背着沃尔特斯-克卢梭%MRMRS%四处转。直到傍晚，%HESHE%%VERB_LETS_LET%才准你回朋友身边。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
你整个下午都背着沃尔特斯-克卢梭%MRMRS%四处转。直到傍晚，%HESHE%才准你回朋友身边。
~~~~

理由：背贵族一下午后才获准离开；let 已由准表达。

### 56. english_events_maingame:L2969 — FIX

事件：`cursedroom`。

英文：
~~~~text
"It happened on my golden yacht in 1974. I was -- HURK! -- cruising my wealthy father's champagne lake with -- BLAAARGH! -- Count Murr D. Erer on the moonlit waves--"
~~~~

审校前：
~~~~text
“1974年，在我的黄金游艇上。我正——呕！——跟穆尔·D.厄勒伯爵，泛舟在父亲的香槟湖上——呕——！月光照着波浪——”
~~~~

审校后（翻译源表）：
~~~~text
“1974年，在我的黄金游艇上。我正——呕！——跟沙·仁·犯伯爵，泛舟在我那有钱老爸的香槟湖上——呕哇！——月光照着波浪——”
~~~~

理由：香槟幽灵讲离奇死亡，Count Murr D. Erer 暗示 murderer；用沙·仁·犯保留一眼可识别的凶手谐音，补回父亲富有的信息。

### 57. english_events_maingame:L3725 — KEEP

事件：`goodhost`。

英文：
~~~~text
You like my puzzle? My friend %CURRENTPLAYERNAME% gave it to me; %HESHE%%VERB_'S_'RE% a kind +N2 SOUL.
~~~~

审校前：
~~~~text
喜欢拼图？朋友%CURRENTPLAYERNAME%送的，%HESHE%%VERB_'S_'RE%真是个善良的+N2灵魂。
~~~~

审校后（翻译源表）：
~~~~text
喜欢拼图？朋友%CURRENTPLAYERNAME%送的，%HESHE%%VERB_'S_'RE%真是个善良的+N2灵魂。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
喜欢拼图？朋友%CURRENTPLAYERNAME%送的，%HESHE%真是个善良的+N2灵魂。
~~~~

理由：善良灵魂兼作 +N2 SOUL 结算，真是已表达系词。

### 58. english_events_maingame:L5032 — POLISH

事件：`crocodiletrick`。

英文：
~~~~text
I'm calling on behalf of %CURRENTPLAYERNAME%; %HESHE% %VERB_IS_ARE% quitting %HISHER% job, effective immediately.
~~~~

审校前：
~~~~text
我是替%CURRENTPLAYERNAME%打来的。%HESHE% %VERB_IS_ARE%要辞掉%HISHER%工作，立即生效。
~~~~

审校后（翻译源表）：
~~~~text
我是替%CURRENTPLAYERNAME%打来的。%HESHE%%VERB_IS_ARE%要辞掉%HISHER%工作，立即生效。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
我是替%CURRENTPLAYERNAME%打来的。%HESHE%要辞掉%HISHER%工作，立即生效。
~~~~

理由：鳄鱼替玩家辞职；中文要辞掉足以表达进行体。

### 59. english_events_maingame:L5034 — KEEP

事件：`crocodiletrick`。

英文：
~~~~text
Yes, %HESHE%%VERB_'S_'RE% absolutely serious. And to really burn the bridge, %HESHE% would like you to know -- and I am quoting %HIMHER% directly here...
~~~~

审校前：
~~~~text
没错，%HESHE%%VERB_'S_'RE%认真的。为了彻底撕破脸，%HESHE%还想让您知道——我直接引用%HIMHER%的原话……
~~~~

审校后（翻译源表）：
~~~~text
没错，%HESHE%%VERB_'S_'RE%认真的。为了彻底撕破脸，%HESHE%还想让您知道——我直接引用%HIMHER%的原话……
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
没错，%HESHE%是认真的。为了彻底撕破脸，%HESHE%还想让您知道——我直接引用%HIMHER%的原话……
~~~~

理由：鳄鱼强调辞职认真并焚桥；展开为是，组成是认真的。

### 60. english_events_maingame:L6016 — POLISH

事件：`bridalbouquet`。

英文：
~~~~text
Uh, wouldn't it make more sense for %CURRENTPLAYERNAME% to just wish on the paw to get married, if that's what %HESHE% %VERB_WANTS_WANT% anyway?
~~~~

审校前：
~~~~text
呃，既然%HESHE% %VERB_WANTS_WANT%结婚，%CURRENTPLAYERNAME%直接对着猴爪许愿结婚，不是更合理吗？
~~~~

审校后（翻译源表）：
~~~~text
呃，既然%HESHE%%VERB_WANTS_WANT%结婚，%CURRENTPLAYERNAME%直接对着猴爪许愿结婚，不是更合理吗？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
呃，既然%HESHE%想结婚，%CURRENTPLAYERNAME%直接对着猴爪许愿结婚，不是更合理吗？
~~~~

理由：猴爪许愿抢花束与直接求婚的逻辑对比；wants 为想。

### 61. english_events_maingame:L6752 — FIX

事件：`liveyourapocalypsefantasy`。

英文：
~~~~text
I could, but %CURRENTPLAYERNAME% doesn't just need a new outfit; %HESHE% %VERB_NEEDS_NEED% a total rebranding.
~~~~

审校前：
~~~~text
可以，不过%CURRENTPLAYERNAME%需要的不只是一套新衣服。%HESHE% %VERB_NEEDS_NEED%要从头重塑个人品牌。
~~~~

审校后（翻译源表）：
~~~~text
可以，不过%CURRENTPLAYERNAME%需要的不只是一套新衣服。%HESHE%%VERB_NEEDS_NEED%从头重塑个人品牌。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
可以，不过%CURRENTPLAYERNAME%需要的不只是一套新衣服。%HESHE%需要从头重塑个人品牌。
~~~~

理由：needs 为需要；删去既有的要，避免展开后需要要。

### 62. english_events_maingame:L7497 — FIX

事件：`palmbestseller`。

英文：
~~~~text
Centaurification is THE erotica subgenre right now, and %HISHER% hoof proves %HESHE% %VERB_FUCKS_FUCK%.
~~~~

审校前：
~~~~text
“半人马化”可是当下最火的情色小分类。%HISHER%蹄子足以证明，%HESHE% %VERB_FUCKS_FUCK%可会做爱了。
~~~~

审校后（翻译源表）：
~~~~text
“半人马化”可是当下最火的情色小分类。%HISHER%蹄子足以证明，%HESHE%可%VERB_FUCKS_FUCK%。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
“半人马化”可是当下最火的情色小分类。%HISHER%蹄子足以证明，%HESHE%可没少干炮。
~~~~

理由：原文 fucks 指确实有性活动，不是性技巧认证；保留情色作品的粗俗口气并消除重复动词。

### 63. english_events_maingame:L7984 — KEEP

事件：`pillageshop`。

英文：
~~~~text
I still don't understand what "pillaging" is. Does it involve pills and aging? Are we here to get old?
~~~~

审校前：
~~~~text
我还是不懂“抢掠”，就是 pillaging。听起来跟吃药、变老有关？咱们是来养老的？
~~~~

审校后（翻译源表）：
~~~~text
我还是不懂“抢掠”，就是 pillaging。听起来跟吃药、变老有关？咱们是来养老的？
~~~~

理由：斯科特把 pillaging 听成 pills 加 aging；现有双语提示完整保留吃药和变老，中文顺序自然，不另造无关笑话。

### 64. english_events_maingame:L8414 — FIX

事件：`wigshop`。

英文：
~~~~text
So you're drawing your magic power from Uranus? Oh, man, THAT is gonna be a branding nightmare.
~~~~

审校前：
~~~~text
所以你的魔力都来自天王星？我去，这名号宣传起来可有得受了。
~~~~

审校后（翻译源表）：
~~~~text
所以你的魔力来自天王星……来自“后门”？我去，这名号宣传起来可有得受了。
~~~~

理由：天王星 Uranus／your anus 的后门笑点导致宣传灾难；在波莉的调侃中补偿另一层含义。

### 65. english_events_maingame:L8415 — KEEP

事件：`wigshop`。

英文：
~~~~text
You take the wig off, because Uranus' power is so explosive that it should only be used in number-one emergencies.
~~~~

审校前：
~~~~text
你摘下假发，毕竟天王星的力量太有爆发性，只有头号紧急情况才能动用。
~~~~

审校后（翻译源表）：
~~~~text
你摘下假发，毕竟天王星的力量太有爆发性，只有头号紧急情况才能动用。
~~~~

理由：保留头号紧急情况，为下一句改口大号留下句式铺垫。

### 66. english_events_maingame:L8416 — FIX

事件：`wigshop`。

英文：
~~~~text
(Or should I say number-TWO emergencies? HAHAHA okay I'll stop now I promise.)
~~~~

审校前：
~~~~text
（或者该说……二号紧急情况？哈哈哈，好啦，我保证不说了。）
~~~~

审校后（翻译源表）：
~~~~text
（或者该说……大号紧急情况？哈哈哈，好啦，我保证不说了。）
~~~~

理由：number two 指大便；大号同时承接头号与天王星的排泄笑话。

### 67. english_events_maingame:L8994 — KEEP

事件：`sellfood`。

英文：
~~~~text
Here, try a free sample: why do we bake cookies, but cook bacon?
~~~~

审校前：
~~~~text
来，免费尝一口：为什么饼干叫 cookies，却用 bake 来做；培根叫 bacon，却用 cook 来做？
~~~~

审校后（翻译源表）：
~~~~text
来，免费尝一口：为什么饼干叫 cookies，却用 bake 来做；培根叫 bacon，却用 cook 来做？
~~~~

理由：食粮式哲学问答；原梗依赖 bake/bacon 与 cook/cookies 的字音，现译明示对应词且保留食物，不改成无关中文脑筋急转弯。

### 68. english_events_maingame:L9495 — POLISH

事件：`howtoshoplift`。

英文：
~~~~text
We know you're %CURRENTPLAYERNAME% in disguise! Officers, arrest %HIMHER% before %HESHE% %VERB_ESCAPES_ESCAPE% and %VERB_KEEPS_KEEP% ripping off the plot of "Face Off!"
~~~~

审校前：
~~~~text
我们知道，你就是乔装的%CURRENTPLAYERNAME%！警官，快逮捕%HIMHER%，别让%HESHE% %VERB_ESCAPES_ESCAPE%，再%VERB_KEEPS_KEEP%照抄《变脸》的剧情！
~~~~

审校后（翻译源表）：
~~~~text
我们知道，你就是乔装的%CURRENTPLAYERNAME%！警官，快逮捕%HIMHER%，别让%HESHE%%VERB_ESCAPES_ESCAPE%，再%VERB_KEEPS_KEEP%照抄《变脸》的剧情！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
我们知道，你就是乔装的%CURRENTPLAYERNAME%！警官，快逮捕%HIMHER%，别让%HESHE%逃走，再继续照抄《变脸》的剧情！
~~~~

理由：追捕与继续照搬变脸情节为两个动作，分别展开为逃走和继续。

### 69. english_events_maingame:L9706 — KEEP

事件：`spreadthecult`。

英文：
~~~~text
Great idea! We could even call them "Mh'athramp Stamps!"
~~~~

审校前：
~~~~text
好主意！还可以起名叫“Mh'athra骚腰印”！
~~~~

审校后（翻译源表）：
~~~~text
好主意！还可以起名叫“Mh'athra骚腰印”！
~~~~

理由：完整教团招募事件为下背部纹身；Mh’athra 神名与骚腰印保留混词两端及性暗示，避免与正文同名纹身脱节。

### 70. english_events_maingame:L10002 — KEEP

事件：`howmuchwork`。

英文：
~~~~text
Yep, %HESHE%%VERB_'S_'VE% gone off the deep end.
~~~~

审校前：
~~~~text
对，%HESHE%%VERB_'S_'VE%彻底走火入魔了。
~~~~

审校后（翻译源表）：
~~~~text
对，%HESHE%%VERB_'S_'VE%彻底走火入魔了。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
对，%HESHE%彻底走火入魔了。
~~~~

理由：拧螺丝成瘾导致走火入魔，完成体由了表达。

### 71. english_events_maingame:L9990 — KEEP

事件：`howmuchwork`。

英文：
~~~~text
But not "screw it" as in "screw it into Panel A." "Screw it" as in "screw this shit, let's leave before we lose any more -N2 HYPE."
~~~~

审校前：
~~~~text
不是说“去把它拧进A面板”，是说“去他妈的，咱们赶紧走，别再损失-N2热度了”。
~~~~

审校后（翻译源表）：
~~~~text
不是说“去把它拧进A面板”，是说“去他妈的，咱们赶紧走，别再损失-N2热度了”。
~~~~

理由：上句是去他的3B螺丝；去把／去他妈的已连接拧螺丝和咒骂，不必另改前句。

### 72. english_events_maingame:L10771 — KEEP

事件：`selfconversation_zoe`。

英文：
~~~~text
A craft of love!
~~~~

审校前：
~~~~text
爱之造物！
~~~~

审校后（翻译源表）：
~~~~text
爱之造物！
~~~~

理由：兹伊自称可爱旧神，爱之造物与下一句毁灭工具形成对比；保留原文正面自我认同，不硬塞作者姓名破坏对话。

### 73. english_events_maingame:L11008 — KEEP

事件：`choosecarnivalgame`。

英文：
~~~~text
"Whack-A-Mole-Person Trying To Get To The Surface" The prize is... guacamole?
~~~~

审校前：
~~~~text
“打鼹鼠人——他们只是想挖到地面上”。奖品是……牛油果酱？
~~~~

审校后（翻译源表）：
~~~~text
“打鼹鼠人——他们只是想挖到地面上”。奖品是……牛油果酱？
~~~~

理由：后续鼹鼠人逃生与来源可疑的牛油果酱完整关联；不为 Whack-a-mole/guacamole 音梗新增提前揭底的打成肉酱情节。

### 74. english_events_maingame:L11095 — KEEP

事件：`choosefreakshow`。

英文：
~~~~text
Mr. "Right To Bear Arms"?
~~~~

审校前：
~~~~text
“持熊臂权”先生？
~~~~

审校后（翻译源表）：
~~~~text
“持熊臂权”先生？
~~~~

理由：完整怪胎秀紧接熊叫，持熊臂权已用持X权句式对应 right to bear arms 的词义错拆。

### 75. english_events_maingame:L12194 — POLISH

事件：`placeyourbets`。

英文：
~~~~text
Ouch! %CURRENTPLAYERNAME% lost. Guess %HESHE%%VERB_'S_'RE% not the good guy of this story.
~~~~

审校前：
~~~~text
哎呀！%CURRENTPLAYERNAME% 输了。看来 %HESHE%%VERB_'S_'RE% 不是这个故事里的好人。
~~~~

审校后（翻译源表）：
~~~~text
哎呀！%CURRENTPLAYERNAME%输了。看来%HESHE%%VERB_'S_'RE%不是这个故事里的好人。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
哎呀！%CURRENTPLAYERNAME%输了。看来%HESHE%不是这个故事里的好人。
~~~~

理由：赌场失利后的电影好人梗；保留不是，删除变量外围多余空格。

### 76. english_events_maingame:L12283 — FIX

事件：`weirdpoker_stage1`。

英文：
~~~~text
%CURRENTPLAYERNAME%'s heart-related bad fortune means %HESHE%%VERB_'S_'RE% lucky at cards, so %HESHE% %VERB_WINS_WIN% the round!
~~~~

审校前：
~~~~text
%CURRENTPLAYERNAME% 情场失意，说明 %HESHE%%VERB_'S_'RE% 赌场得意，所以这局 %HESHE% %VERB_WINS_WIN% 赢了！
~~~~

审校后（翻译源表）：
~~~~text
%CURRENTPLAYERNAME%情场失意，说明%HESHE%%VERB_'S_'RE%赌场得意，所以这局%HESHE%%VERB_WINS_WIN%了！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
%CURRENTPLAYERNAME%情场失意，说明%HESHE%赌场得意，所以这局%HESHE%赢了！
~~~~

理由：情场失意赌场得意保留；wins 直接译为赢，删去原来重复的赢。

### 77. english_events_maingame:L12379 — KEEP

事件：`weirdpoker_stage2`。

英文：
~~~~text
WOW! Five club cards! It's a flush!
~~~~

审校前：
~~~~text
哇！五张夜店牌！清一色夜店，同花！
~~~~

审校后（翻译源表）：
~~~~text
哇！五张夜店牌！清一色夜店，同花！
~~~~

理由：上句明确是五家夜店名片，下句再玩 house/full house；清一色夜店、同花已接通纸牌与名片逻辑。

### 78. english_events_maingame:L12439 — FIX

事件：`weirdpoker_stage3`。

英文：
~~~~text
The gunman sighs. "Fine... I sort of want to see what %HESHE% %VERB_HAS_HAD% anyway. Very well, flip it over."
~~~~

审校前：
~~~~text
枪手叹了口气：“好吧……我也有点想看 %HESHE% %VERB_HAS_HAD% 手里是什么。行，翻开吧。”
~~~~

审校后（翻译源表）：
~~~~text
枪手叹了口气：“好吧……我也有点想看看%HESHE%手里%VERB_HAS_HAD%什么牌。行，翻开吧。”
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
枪手叹了口气：“好吧……我也有点想看看%HESHE%手里有什么牌。行，翻开吧。”
~~~~

理由：枪手想看玩家手里有什么牌，HAS_HAD 拼错不影响同一上下文的有义；重新安排手里有的中文顺序。

### 79. english_events_maingame:L12477 — FIX

事件：`weirdpoker_stage3`。

英文：
~~~~text
The gunman sighs. "Fine... I sort of want to see what %HESHE% %VERB_HAS_HAD% too. Very well, flip it over."
~~~~

审校前：
~~~~text
枪手叹了口气：“好吧……我也有点想看看 %HESHE% %VERB_HAS_HAD% 手里是什么。行，翻开吧。”
~~~~

审校后（翻译源表）：
~~~~text
枪手叹了口气：“好吧……我也有点想看看%HESHE%手里%VERB_HAS_HAD%什么牌。行，翻开吧。”
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
枪手叹了口气：“好吧……我也有点想看看%HESHE%手里有什么牌。行，翻开吧。”
~~~~

理由：枪手想看玩家手里有什么牌，HAS_HAD 拼错不影响同一上下文的有义；重新安排手里有的中文顺序。

### 80. english_events_maingame:L14403 — POLISH

事件：`increaseaerialstakes`。

英文：
~~~~text
WHAT ABOUT %CURRENTPLAYERNAMECAPS%? WE CAN 100% OBJECTIFY %HISHERCAPS% ASS, AND WE'RE COOL IF %HESHECAPS% %VERBCAPS_DIES_DIE%!
~~~~

审校前：
~~~~text
%CURRENTPLAYERNAMECAPS% 呢？%HISHERCAPS% 屁股，我们想怎么看就怎么看，%HESHECAPS% %VERBCAPS_DIES_DIE% 死了也没关系！
~~~~

审校后（翻译源表）：
~~~~text
%CURRENTPLAYERNAMECAPS%呢？%HISHERCAPS%屁股，我们想怎么看就怎么看，%HESHECAPS%%VERBCAPS_DIES_DIE%了也没关系！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
%CURRENTPLAYERNAMECAPS%呢？%HISHERCAPS%屁股，我们想怎么看就怎么看，%HESHECAPS%死了也没关系！
~~~~

理由：狼群既要看屁股又不在乎玩家死亡；DIES 译死，保留 CAPS 标记且不重复死字。

### 81. english_events_maingame:L14460 — POLISH

事件：`increaseaerialstakes`。

英文：
~~~~text
NOOOOOOOO! They got %CURRENTPLAYERNAME% to chicken out; %HESHE%%VERB_'S_'RE% walking away!
~~~~

审校前：
~~~~text
不——！他们把 %CURRENTPLAYERNAME% 劝怂了，%HESHE%%VERB_'S_'RE% 要走了！
~~~~

审校后（翻译源表）：
~~~~text
不——！他们把%CURRENTPLAYERNAME%劝怂了，%HESHE%%VERB_'S_'RE%要走了！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
不——！他们把%CURRENTPLAYERNAME%劝怂了，%HESHE%要走了！
~~~~

理由：被朋友劝退后离开，进行体由要走了表达。

### 82. english_events_maingame:L15128 — KEEP

事件：`obstaclestyle`。

英文：
~~~~text
Wolf Scott, do you believe inaction equals culpability? Do you believe saving five lives is worth sparing one?!
~~~~

审校前：
~~~~text
狼斯科特，你觉得不作为等于有罪吗？为了救五个人，值得牺牲一个吗？！
~~~~

审校后（翻译源表）：
~~~~text
狼斯科特，你觉得不作为等于有罪吗？为了救五个人，值得牺牲一个吗？！
~~~~

理由：前句明确改道杀一救五，后句明确杀一或杀五；sparing 是源文笔误，现译牺牲一人符合两侧证据。

### 83. english_events_maingame:L15625 — POLISH

事件：`prankevil`。

英文：
~~~~text
Well, it is OBVIOUS %HESHE% %VERB_IS_ARE% running slower than superman.
~~~~

审校前：
~~~~text
显然，%HESHE% %VERB_IS_ARE% 跑得比超人慢。
~~~~

审校后（翻译源表）：
~~~~text
显然，%HESHE%%VERB_IS_ARE%跑得比超人慢。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
显然，%HESHE%跑得比超人慢。
~~~~

理由：超人比赛对话；跑得更慢无需额外系词。

### 84. english_events_maingame:L15628 — FIX

事件：`prankevil`。

英文：
~~~~text
I think %HESHE% %VERB_MEANS_MEAN% it as a sort of proportional thing? Like the model of a building.
~~~~

审校前：
~~~~text
我想，%HESHE% %VERB_MEANS_MEAN% 是按某种比例算？就像建筑模型。
~~~~

审校后（翻译源表）：
~~~~text
我想，%HESHE%%VERB_MEANS_MEAN%是按某种比例算？就像建筑模型。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
我想，%HESHE%的意思是按某种比例算？就像建筑模型。
~~~~

理由：means it as 指玩家的意思，不是缺省掉该实义；用的意思衔接主语。

### 85. english_events_maingame:L15629 — POLISH

事件：`prankevil`。

英文：
~~~~text
So, while of course %HESHE% can't run as fast as Superman, if %HESHE% %VERB_WAS_WERE% a Kryptonian version of %HIMHER%self, WOULD %HESHE% be faster than Superman?
~~~~

审校前：
~~~~text
所以，虽然 %HESHE% 肯定跑不过超人，可假如 %HESHE% %VERB_WAS_WERE% 氪星版的 %HIMHER% 自己，那 %HESHE% 会不会比超人快？
~~~~

审校后（翻译源表）：
~~~~text
所以，%HESHE%当然跑不过超人，可如果%HESHE%%VERB_WAS_WERE%氪星人——就是氪星版的%HIMHER%——那%HESHE%会不会比超人快？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
所以，%HESHE%当然跑不过超人，可如果%HESHE%是氪星人——就是氪星版的%HIMHER%——那%HESHE%会不会比超人快？
~~~~

理由：保留假设玩家成为氪星版本及全部人称出现；was/were 在这里必须为是。

### 86. english_events_maingame:L15636 — POLISH

事件：`prankevil`。

英文：
~~~~text
So if %CURRENTPLAYERNAME% can run faster than me, then we know %HESHE% would be faster than Superman provided %HESHE% %VERB_WAS_WERE% Kryptonian.
~~~~

审校前：
~~~~text
所以，只要 %CURRENTPLAYERNAME% 比我快，就知道，假如 %HESHE% %VERB_WAS_WERE% 氪星人，%HESHE% 就会比超人快。
~~~~

审校后（翻译源表）：
~~~~text
所以，只要%CURRENTPLAYERNAME%比我快，就说明假如%HESHE%%VERB_WAS_WERE%氪星人，%HESHE%就会比超人快。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
所以，只要%CURRENTPLAYERNAME%比我快，就说明假如%HESHE%是氪星人，%HESHE%就会比超人快。
~~~~

理由：德米特里用自身训练结果作比较基准；条件句系词为是。

### 87. english_events_maingame:L15796 — POLISH

事件：`tournamentarc_stage1`。

英文：
~~~~text
Oh... do you think %HESHE%%VERB_'S_'VE% noticed %HISHER% kite flew away on an updraft?
~~~~

审校前：
~~~~text
哦……你觉得 %HESHE%%VERB_'S_'VE% 发现 %HISHER% 风筝被上升气流卷走了吗？
~~~~

审校后（翻译源表）：
~~~~text
哦……你觉得%HESHE%%VERB_'S_'VE%发现%HISHER%风筝被上升气流卷走了吗？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
哦……你觉得%HESHE%发现%HISHER%风筝被上升气流卷走了吗？
~~~~

理由：风筝被上升气流带走后追问玩家是否发现；完成体由了吗表达。

### 88. english_events_maingame:L15839 — POLISH

事件：`tournamentarc_stage2`。

英文：
~~~~text
%HESHE% may win the kite tournament... but %HESHE% %VERB_HAS_HAVE% lost the friendship tournament...
~~~~

审校前：
~~~~text
%HESHE% 或许赢了风筝大赛……可 %HESHE% %VERB_HAS_HAVE% 输了友谊大赛……
~~~~

审校后（翻译源表）：
~~~~text
%HESHE%或许赢了风筝大赛……可%HESHE%%VERB_HAS_HAVE%输了友谊大赛……
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
%HESHE%或许赢了风筝大赛……可%HESHE%输了友谊大赛……
~~~~

理由：此处 HAS_HAVE 是完成体而非拥有，输了已经表达。

### 89. english_events_maingame:L17971 — POLISH

事件：`impossiblealcoholtest`。

英文：
~~~~text
%CURRENTPLAYERNAME%: no, 'cause %HESHE%%VERB_'S_'RE% driving. Me, on the other hand: fuuuuuuck yes.
~~~~

审校前：
~~~~text
%CURRENTPLAYERNAME% 没喝，%HESHE%%VERB_'S_'RE% 得开车。至于我：他妈的当然喝了。
~~~~

审校后（翻译源表）：
~~~~text
%CURRENTPLAYERNAME%没喝，%HESHE%%VERB_'S_'RE%得开车。至于我：他妈的当然喝了。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
%CURRENTPLAYERNAME%没喝，%HESHE%得开车。至于我：他妈的当然喝了。
~~~~

理由：交警问饮酒情况，波莉承认自己喝酒而驾驶员没喝；进行体无需英文系词。

### 90. english_events_maingame:L17989 — POLISH

事件：`impossiblealcoholtest`。

英文：
~~~~text
"Maybe we could meet up for drinks sometime?" Hey, %HESHE%%VERB_'S_'RE% thinking about drinks! That's the first step to being drunk!
~~~~

审校前：
~~~~text
“有空一起喝一杯吗？”嘿，%HESHE%%VERB_'S_'RE% 都开始惦记喝酒了！这是喝醉的第一步！
~~~~

审校后（翻译源表）：
~~~~text
“有空一起喝一杯吗？”嘿，%HESHE%%VERB_'S_'RE%都开始惦记喝酒了！这是喝醉的第一步！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
“有空一起喝一杯吗？”嘿，%HESHE%都开始惦记喝酒了！这是喝醉的第一步！
~~~~

理由：警察把约喝一杯当醉酒征兆；惦记已表达进行含义。

### 91. english_events_maingame:L18382 — POLISH

事件：`hidemagicartifact`。

英文：
~~~~text
You definitely don't look like the %CURRENTPLAYERNAME% who told us %HESHE% %VERB_KNOWS_KNOW% a ton of awesome BMX tricks.
~~~~

审校前：
~~~~text
你可不像那个跟我们吹牛，说 %HESHE% %VERB_KNOWS_KNOW% 一大堆超酷 BMX 车技的 %CURRENTPLAYERNAME%。
~~~~

审校后（翻译源表）：
~~~~text
你可不像那个跟我们吹牛，说%HESHE%%VERB_KNOWS_KNOW%一大堆超酷BMX车技的%CURRENTPLAYERNAME%。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
你可不像那个跟我们吹牛，说%HESHE%会一大堆超酷BMX车技的%CURRENTPLAYERNAME%。
~~~~

理由：酷人设被揭穿；知道车技在此为会车技。

### 92. english_events_maingame:L19138 — POLISH

事件：`potiondrinks`。

英文：
~~~~text
Hey, I bet %CURRENTPLAYERNAME% would do it; %HESHE%%VERB_'S_'VE% been a chaotic motherfucker since day one.
~~~~

审校前：
~~~~text
嘿，%CURRENTPLAYERNAME% 肯定愿意，%HESHE%%VERB_'S_'VE% 从第一天起就是个唯恐天下不乱的混蛋。
~~~~

审校后（翻译源表）：
~~~~text
嘿，%CURRENTPLAYERNAME%肯定愿意，%HESHE%%VERB_'S_'VE%从第一天起就是个唯恐天下不乱的混蛋。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
嘿，%CURRENTPLAYERNAME%肯定愿意，%HESHE%从第一天起就是个唯恐天下不乱的混蛋。
~~~~

理由：赫克斯鼓动试药的粗口；原来的从第一天起就是已表达完成体。

### 93. english_events_maingame:L19174 — FIX

事件：`potiondrinks`。

英文：
~~~~text
That way when %HESHE% %VERB_DRINKS_DRINK% the potion, %HESHE%'ll have no idea who %HESHE%'ll see when %HESHE% %VERB_OPENS_OPEN% %HISHER% eyes! We'll call it "Love Is Blind-FOLDED"!
~~~~

审校前：
~~~~text
这样等 %HESHE% %VERB_DRINKS_DRINK% 药水以后，%HESHE% 也不知道，等 %HESHE% %VERB_OPENS_OPEN% %HISHER% 眼睛时，%HESHE% 会先看见谁！就叫《爱情蒙眼选》！
~~~~

审校后（翻译源表）：
~~~~text
这样等%HESHE%%VERB_DRINKS_DRINK%药水，%HESHE%就完全猜不到，%HESHE%%VERB_OPENS_OPEN%%HISHER%眼睛时，%HESHE%会看见谁！就叫《爱情蒙眼选》！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
这样等%HESHE%喝下药水，%HESHE%就完全猜不到，%HESHE%睁开%HISHER%眼睛时，%HESHE%会看见谁！就叫《爱情蒙眼选》！
~~~~

理由：蒙眼喝药与睁眼爱上第一眼的人，保留四次 HESHE；重新组织中文顺序并消除动词空缺。

### 94. english_events_maingame:L21131 — KEEP

事件：`uniquemoments`。

英文：
~~~~text
I'm sure %CURRENTPLAYERNAME% can help; %HESHE%%VERB_'S_'RE% pretty good at schemes! Got any ideas, bro?
~~~~

审校前：
~~~~text
%CURRENTPLAYERNAME%肯定能帮忙，%HESHE%%VERB_'S_'RE%可是出点子的高手！兄弟，有什么主意？
~~~~

审校后（翻译源表）：
~~~~text
%CURRENTPLAYERNAME%肯定能帮忙，%HESHE%%VERB_'S_'RE%可是出点子的高手！兄弟，有什么主意？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
%CURRENTPLAYERNAME%肯定能帮忙，%HESHE%可是出点子的高手！兄弟，有什么主意？
~~~~

理由：派对鬼魂请求出点子；可是高手已表达系词。

### 95. english_events_maingame:L21749 — POLISH

事件：`parkworkers_stage2`。

英文：
~~~~text
You're holding %CURRENTPLAYERNAME% at gunpoint?! God, %HESHE% %VERB_DOESN'T_DON'T% even have her dumb nose; %HESHE%%VERB_'S_'RE% obviously just making shapes with %HISHER% hands!
~~~~

审校前：
~~~~text
你们竟然拿枪指着%CURRENTPLAYERNAME%？！天哪，%HESHE% %VERB_DOESN'T_DON'T%拿走她那个破鼻子；%HESHE%%VERB_'S_'RE%明明只是在用%HISHER%手比个形状！
~~~~

审校后（翻译源表）：
~~~~text
你们竟然拿枪指着%CURRENTPLAYERNAME%？！天哪，%HESHE%%VERB_DOESN'T_DON'T%拿走她那个破鼻子；%HESHE%%VERB_'S_'RE%明明只是在用%HISHER%手比个形状！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
你们竟然拿枪指着%CURRENTPLAYERNAME%？！天哪，%HESHE%根本没拿走她那个破鼻子；%HESHE%明明只是在用%HISHER%手比个形状！
~~~~

理由：偷鼻子是拇指把戏，否定必须保留；does not 为根本没，不能一律清空。

### 96. english_events_maingame:L21776 — KEEP

事件：`parkworkers_stage2`。

英文：
~~~~text
I disagree. I mean, %HESHE%%VERB_'S_'RE% already vomiting, and it's not even six p.m. Even I could hold my liquor better than that.
~~~~

审校前：
~~~~text
我不同意。你看，%HESHE%%VERB_'S_'RE%已经吐了，现在连下午六点都没到。就连我都比这能喝。
~~~~

审校后（翻译源表）：
~~~~text
我不同意。你看，%HESHE%%VERB_'S_'RE%已经吐了，现在连下午六点都没到。就连我都比这能喝。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
我不同意。你看，%HESHE%已经吐了，现在连下午六点都没到。就连我都比这能喝。
~~~~

理由：人事代表反驳耐酒量，已经吐了是完整进行状态。

### 97. english_events_maingame:L22010 — FIX

事件：`internationalwaters`。

英文：
~~~~text
Avast, ye digital scurvy dogs! Here's your pirated photo-editing software, filled with all the airbrushed booty you can imagine!
~~~~

审校前：
~~~~text
听着，你们这帮数码恶棍！盗版修图软件来了，里面有你能想象到的各种精修“宝贝”！
~~~~

审校后（翻译源表）：
~~~~text
听着，你们这帮数码恶棍！盗版修图软件来了，里面全是精修过的翘臀“宝藏”，你想要什么样的都有！
~~~~

理由：盗版软件卖给海盗；booty 同为战利品及臀部，用翘臀宝藏保留两层。

### 98. english_events_maingame:L22089 — KEEP

事件：`tarottournament_stage1`。

英文：
~~~~text
I see... %HESHE% only %VERB_NEEDS_NEED% to use cards that play into a strong aspect of %HISHER% spirit... %HESHE% must be true to %HIMSELFHERSELF%!
~~~~

审校前：
~~~~text
明白了……%HESHE%只%VERB_NEEDS_NEED%打出符合%HISHER%精神强项的牌……%HESHE%必须忠于%HIMSELFHERSELF%！
~~~~

审校后（翻译源表）：
~~~~text
明白了……%HESHE%只%VERB_NEEDS_NEED%打出符合%HISHER%精神强项的牌……%HESHE%必须忠于%HIMSELFHERSELF%！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
明白了……%HESHE%只需要打出符合%HISHER%精神强项的牌……%HESHE%必须忠于%HIMSELFHERSELF%！
~~~~

理由：强项对应玩法资源，needs 在此译需要。

### 99. english_events_maingame:L22114 — FIX

事件：`tarottournament_stage1`。

英文：
~~~~text
Hope's Moon can twerk at the Earth as much as it wants... Earth will be rendered inhabitable pretty soon, anyway.
~~~~

审校前：
~~~~text
希望女巫的月亮想冲着地球怎么扭屁股都行……反正地球很快就会变得适合居住了。
~~~~

审校后（翻译源表）：
~~~~text
希望女巫的月亮想冲着地球怎么扭屁股都行……反正地球很快就没法住人了。
~~~~

理由：前选项和后文反复说明富豪毁坏地球后逃去火星；inhabitable 疑漏 un-，据完整分支修正原来反向的意思。

### 100. english_events_maingame:L22423 — KEEP

事件：`tarottournament_stage3`。

英文：
~~~~text
It predicts %CURRENTPLAYERNAME% realizing and coming to terms with the fact that %HESHE% barely %VERB_KNOWS_KNOW% how to play this game!
~~~~

审校前：
~~~~text
它预示着，%CURRENTPLAYERNAME%终于看清并接受了现实：%HESHE%几乎不%VERB_KNOWS_KNOW%这游戏该怎么玩！
~~~~

审校后（翻译源表）：
~~~~text
它预示着，%CURRENTPLAYERNAME%终于看清并接受了现实：%HESHE%几乎不%VERB_KNOWS_KNOW%这游戏该怎么玩！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
它预示着，%CURRENTPLAYERNAME%终于看清并接受了现实：%HESHE%几乎不知道这游戏该怎么玩！
~~~~

理由：希望女巫嘲讽玩家不懂规则，knows 为知道。

### 101. english_events_maingame:L22429 — POLISH

事件：`tarottournament_stage3`。

英文：
~~~~text
It represents the fact that %CURRENTPLAYERNAME% is riddled with so much embarrassment that %HESHE% %VERB_WANTS_WANT% to dig a hole and bury %HIMSELFHERSELF% in it!
~~~~

审校前：
~~~~text
它代表，%CURRENTPLAYERNAME%已经尴尬得受不了，%HESHE% %VERB_WANTS_WANT%挖个洞，把%HIMSELFHERSELF%埋进去！
~~~~

审校后（翻译源表）：
~~~~text
它代表，%CURRENTPLAYERNAME%已经尴尬得受不了，%HESHE%%VERB_WANTS_WANT%挖个洞，把%HIMSELFHERSELF%埋进去！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
它代表，%CURRENTPLAYERNAME%已经尴尬得受不了，%HESHE%想挖个洞，把%HIMSELFHERSELF%埋进去！
~~~~

理由：尴尬到想钻地洞，wants 为想。

### 102. english_events_maingame:L22437 — POLISH

事件：`tarottournament_stage3`。

英文：
~~~~text
Heh... exactly. One could say %HESHE% %VERB_IS_ARE%... hopeless.
~~~~

审校前：
~~~~text
呵……没错。可以说，%HESHE% %VERB_IS_ARE%……没“希望”了。
~~~~

审校后（翻译源表）：
~~~~text
呵……没错。可以说，%HESHE%%VERB_IS_ARE%……没“希望”了。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
呵……没错。可以说，%HESHE%……没“希望”了。
~~~~

理由：hopeless 既无望又被希望女巫打败；保留引号，不再输出系词。

### 103. english_events_maingame:L22473 — POLISH

事件：`tarottournament_stage3`。

英文：
~~~~text
Ugh, %HESHE% %VERB_IS_ARE% predicting anyone's future!
~~~~

审校前：
~~~~text
唉，%HESHE% %VERB_IS_ARE%预言的，是所有人都会遇到的未来！
~~~~

审校后（翻译源表）：
~~~~text
唉，%HESHE%%VERB_IS_ARE%预言的，是所有人都会遇到的未来！
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
唉，%HESHE%预言的，是所有人都会遇到的未来！
~~~~

理由：预言只说人人都会老，被斯科特曲解成能预言所有人的能力；现译关系准确。

### 104. english_events_maingame:L23552 — KEEP

事件：`realmorigins_stage1`。

英文：
~~~~text
Besides the usual? Dunno, but %HISHER% face looks weird for sure. Maybe %HESHE%%VERB_'S_'RE% holding in a fart?
~~~~

审校前：
~~~~text
你说，除了平常那点毛病？不知道，反正%HISHER%表情怪怪的。也许%HESHE%%VERB_'S_'RE%在憋屁？
~~~~

审校后（翻译源表）：
~~~~text
你说，除了平常那点毛病？不知道，反正%HISHER%表情怪怪的。也许%HESHE%%VERB_'S_'RE%在憋屁？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
你说，除了平常那点毛病？不知道，反正%HISHER%表情怪怪的。也许%HESHE%在憋屁？
~~~~

理由：玩家搬桌子使劲被误认为憋屁；在憋屁已表达进行体。

### 105. english_events_maingame:L24211 — POLISH

事件：`cryptidwtf_stage2`。

英文：
~~~~text
Well, I'd say since %CURRENTPLAYERNAME% made this super-smart choice, %HESHE% %VERB_GETS_GET% to fight this one.
~~~~

审校前：
~~~~text
既然是%CURRENTPLAYERNAME%做了这么聪明的选择，那就由%HESHE% %VERB_GETS_GET%来打吧。
~~~~

审校后（翻译源表）：
~~~~text
既然是%CURRENTPLAYERNAME%做了这么聪明的选择，那就由%HESHE%%VERB_GETS_GET%来打吧。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
既然是%CURRENTPLAYERNAME%做了这么聪明的选择，那就由%HESHE%来打吧。
~~~~

理由：波莉让作出选择的玩家负责打恐龙；get to 由就由表达，不再添获得。

### 106. english_events_maingame:L24220 — FIX

事件：`cryptidwtf_stage2`。

英文：
~~~~text
Polly, look, %HESHE% %VERB_IS_ARE% getting devoured by the dinosaur. Do you think it's all part of a clever plan?
~~~~

审校前：
~~~~text
波莉，你看，%HESHE% %VERB_IS_ARE%被恐龙吃了。你觉得，会不会是某个高明计划的一部分？
~~~~

审校后（翻译源表）：
~~~~text
波莉，你看，%HESHE%%VERB_IS_ARE%正被恐龙吞进肚子里呢。你觉得会不会是某个高明计划的一部分？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
波莉，你看，%HESHE%正被恐龙吞进肚子里呢。你觉得会不会是某个高明计划的一部分？
~~~~

理由：getting devoured 是正在被吞吃，不是已经吃完；斯科特还在旁观并猜是不是计策。

### 107. english_events_maingame:L26171 — POLISH

事件：`glitchspookyacademy`。

英文：
~~~~text
What %VERB_IS_ARE% %HESHE% doing?
~~~~

审校前：
~~~~text
%HESHE%在干什么%VERB_IS_ARE%？
~~~~

审校后（翻译源表）：
~~~~text
%HESHE%%VERB_IS_ARE%在干什么？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
%HESHE%在干什么？
~~~~

理由：把保留的助动词放到主语后，加载时不译；不把英文 is 遗留在句末。

### 108. english_events_maingame:L26172 — POLISH

事件：`glitchspookyacademy`。

英文：
~~~~text
If I recall correctly, %HESHE%%VERB_'S_'RE% becoming a minister.
~~~~

审校前：
~~~~text
没记错的话，%HESHE%%VERB_'S_'RE%正在成为一名牧师。
~~~~

审校后（翻译源表）：
~~~~text
没记错的话，%HESHE%%VERB_'S_'RE%正准备当牧师。
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
没记错的话，%HESHE%正准备当牧师。
~~~~

理由：前后文是取得牧师身份以祝圣教室，正在成为不自然，改为正准备当。

### 109. english_events_pitstop:L1968 — KEEP

事件：`pitstop_passenger_lovefail_polly_2`。

英文：
~~~~text
Like, %HESHE%%VERB_'S_'RE% a good friend and I appreciate %HIMHER%, but dang... can't %HESHE% try not to murder my vibe?
~~~~

审校前：
~~~~text
就是说，%HESHE%%VERB_'S_'RE%个好朋友，我也很珍惜 %HIMHER%，但拜托……%HESHE%能不能别总把我的兴致一刀捅死？
~~~~

审校后（翻译源表）：
~~~~text
就是说，%HESHE%%VERB_'S_'RE%个好朋友，我也很珍惜 %HIMHER%，但拜托……%HESHE%能不能别总把我的兴致一刀捅死？
~~~~

中文动词展开后（其余变量仍交由游戏处理）：
~~~~text
就是说，%HESHE%是个好朋友，我也很珍惜 %HIMHER%，但拜托……%HESHE%能不能别总把我的兴致一刀捅死？
~~~~

理由：波莉向母亲抱怨朋友扫兴；此句缺独立中文系词，变量须展开为是，不能与其他同名变量一律清空。
