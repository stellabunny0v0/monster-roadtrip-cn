# 新系列 reference 回查记录

已完成冻结范围 4,835 条的回查，未将名字扫描计入新增审校覆盖量。

- 称名／术语单独修正：348 条，见 `series-name-fixes-001.csv`。
- 全句及上下文回查：KEEP 4,624、FIX 149、POLISH 33、REVIEW 29。
- 称名修正之后，另有 183 条译文发生修改（149 FIX、33 POLISH、1 仍为 REVIEW）。
- 原先 pass-001 至 pass-022 的日志保持为历史记录，最终回查译文见 series-recheck-001 至 015。
- 不确定物品形态、引用、源文件标签与双关继续保持待确认；29 条没有被算成定稿。

## 已裁决的命名扫描例外

扫描器把“惊悚学院”也列为 Spooky High 的旧译，但以下源文指向的是更名后的 Spooky Academy，不应改回旧校名。

| row_id | 裁决 |
|---|---|
| english_metatexts:RML_SPOOKY_ACADEMY | 地点名称 Spooky Academy，保留惊悚学院 |
| english_metatexts:GLR_ECK_GLITCHSPOOKYACADEMY | Return to Spooky Academy，保留惊悚学院 |
| english_events_pitstop:L3438 | 莫斯明确谈及改名为 Spooky Academy，保留区别 |
| english_events_pitstop:L3439 | 承接该新校名，保留区别 |
| english_events_standard:L625 | 源文 Spooky Academy，统一为惊悚学院 |

续审第 023 批 `english_events_pitstop:L3670` 同样明确是 Spooky Academy，按同一规则处理。
真实制作人员、普通 joy/hope/faith、一般狼群、玩家自定义姓名变量均不按角色专名盲目替换。
全名额外逐条核对，修正了序章 Scott Howl 与 Polly Geist 的旧姓氏译法。

## 回查完成后的续审

按用户要求直接恢复，无需再次确认。第 023–027 批使用 monster-prom-series-zh，新增 503 条：KEEP 19、FIX 346、POLISH 136、REVIEW 2。
计算斯基的两处伪代码台词按受保护标记保留，另列待确认。新覆盖量不包含任何回查条目。

## 校验

全部 CSV 的行数、ID、英文及非翻译字段保持不变；覆盖表与当前译文同步；占位符、CSV 和运行时控制字段校验通过。
命名候选逐条按源文裁决，没有未处理的已核实人物异译。生成了本地 build/package；没有实机验证、安装、改写存档或发布新版本。
