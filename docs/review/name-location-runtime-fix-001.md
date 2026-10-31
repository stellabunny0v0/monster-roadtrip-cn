# v0.3.5：中文姓名与地点名称

日期：2026-10-30。用户报告重新载入后主角姓名变成三个问号，The Dinest 地点名仍是英文，并要求核查所有地点。

## 中文姓名的证据与修复

- 只读核对旧启动备份中的断点，南瓜主角（PlayerA / pumpkin）的 Name 字段确实已经为 ASCII 的 ???。没有修改或恢复任何旧断点文件。
- 原版 XmlSerializer.GenerateXMLFileStream 使用 XmlTextWriter(MemoryStream, new ASCIIEncoding())；SerializeCorePlayerData 随后用 WriteElementString 写入姓名。独立内存复现证明，三个中文字符会直接变成三个问号；不是单纯字体问题。
- v0.3.5 只在 CoreCheckpointXmlSerializer.SerializeCorePlayerData 内重定向两参数 WriteElementString 调用到辅助函数。辅助函数仅对 Name 元素使用 XML 数字字符实体，其余元素调用原方法。原 XML 结构、ID、属性值、加密及文件命名／轮换机制不变。
- 读档时的旧损坏姓名只能按用户明确告知的原名恢复。默认 Rules 为空，不推测名字；本机 BepInEx 配置在 NameRecovery 节使用 Rules，格式为 玩家ID|角色ID|损坏值|原名，多个规则用分号分隔。仅纯问号且四个字段精确匹配才恢复，正常姓名不变。
- 用户随后确认应为“杰奎琳”。已仅在本机配置 PlayerA / pumpkin / ??? 对应杰奎琳；恢复发生在反序列化后的内存对象，现有存档原文件未重写。之后由游戏正常保存的中文姓名会采用兼容 ASCII 的 XML 实体保护。
- 本机 BepInEx 配置不在仓库或发行包目录；不得把本机个性化恢复规则放进公共安装包。

## 地点核查

地图使用 TextManager 的 RML_*，目的地使用 DTT_*。完整检查共 83 个 UI 名称：77 个地点（含旅途终点变体）与 6 个目的地。原来还有 The Dinest 两个变体、Simon Soups、Veranotone 共 4 个标题没有中文，现全部已补齐。

- The Dinest → 至臻餐厅（classy / discerning tastes 的高档餐馆，项目工作译名）。
- Simon Soups 餐馆 → 西蒙汤馆；指角色时 → 西蒙·汤，不混用。
- Veranotone → 维拉诺顿，目的地标题为维拉诺顿音乐节。遵照本次地点中文覆盖要求，取代此前保留英文的编辑决定，未声称为官方名称。

相关对白、画廊标题和变体共 42 条定点同步，见 location-name-fixes-001.csv；不增加首次语言审校覆盖量。全部名称中英表见 location-names-001.md。translation/location_names_zh.json 记录已审映射，CSV 与运行时产物均校验覆盖、中文名称和一致性，后续漏键或退回英文会失败。

读档会按地点 ID 重新创建 RoadmapLocationData，并通过 GetNewLocationData 读取当前词表；断点保存的是地点 ID，没有为显示译名重写旧地图或更改地点 ID。

## 验证与安装

- 26 项 Python 测试通过，含地图标题、缺失键、EOTR、陈旧运行时标题及既有显示文字／结算／动词测试。
- 姓名 C# 内存测试通过：复现旧 ASCII 损坏，检查 7 种中英文／特殊字符／补充字符姓名的 ASCII XML 与 UTF-8 加密载荷往返；ID、属性值和旧 ASCII 格式不变；明确恢复规则和不覆盖自定义姓名的保护通过。
- 实际游戏程序集只读 IL 检查通过：编译后补丁重定向姓名序列化方法的 10 个 XML 写入调用，所有其他指令不变。未执行游戏存档方法。
- 既有属性结算回归仍对齐 1,342 个标记、1,062 行和 27 处奖励；59 条动词适配仍通过实际 C# 消费函数验证。
- 翻译及运行时校验通过，插件 Release 编译 0 警告、0 错误。
- 已备份旧插件并安装 v0.3.5，14 个插件／译文文件哈希一致；仅该插件自身配置新增本机恢复规则。安装前后 12 个 UserData 文件内容完全一致。

未启动游戏验收，不标记 ingame-ok；需要用户重启游戏，读取继续存档，确认姓名、地点名及下一次正常保存后重载结果。
