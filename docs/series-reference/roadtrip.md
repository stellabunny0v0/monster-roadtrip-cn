# 当前 Monster Roadtrip 项目的审校工作流

此页仅适用于 `monster-roadtrip-cn`。从当前工作区定位该目录；原工作区为 `C:/Users/30364/OneDrive/文档/ChatGPT/神秘小项目`。以下路径相对仓库，命令从仓库目录运行。

## 开始与范围

- 先检查工作区现有修改，保留其他任务的工作。续审时查询 `docs/review/progress.json` 和相关批次记录，只读取定位本批所需的部分，不重新审整库。
- `translation/english_*.csv` 按 `row_id` 对齐；英文为 `source`，中文为 `target`。保留 `row_id/source_file/source_line` 等结构字段。按完整 `event_id` 读取前后对白、选项及各结果，避免孤立逐行改写。
- 人名与系列默认值查询 `docs/series-reference/glossary.json`；新作独有术语查询 `translation/glossary.json`。用户新指定优先。UI、资源或当前项目的特殊术语另查 `docs/STYLE_GUIDE_ZH.md`；不再要求全量加载重复的系列指南。

## 落盘与记录

- 编辑 CSV 的 `target`，保留未改部分。`translation/seed_zh.json`、`translation/quality_overrides_zh.json` 中已有的同 `row_id` 覆盖必须同步，否则重放覆盖会还原改动；两覆盖表不得新增重复键。
- 使用现有批次日志格式记录决定；核对既有日志后更新进度，不以覆盖表生成的 `status/notes` 判断是否已逐句审过。待确认内容不能因为重放覆盖被记为完成。
- `status/notes` 如实反映本批处理；`ingame-ok` 仅用于实际实机确认。不要凭人名扫描改变全量审校计数。
- `extracted/original/` 是源导出；`build/package/BepInEx/plugins/MonsterRoadtripChinese/Translation/` 是构建结果，不能只改生成文件。

## 格式约束与校验

- `%CURRENTPLAYERNAME%`、`%HESHE%`、`[0]`、`[n]`、其他变量及富文本原样保留；CSV 译文不能含字面换行或制表符。运行时事件 TSV 仅第四列正文可译，角色、表情、条件和音效等控制列不变。
- 六项 `STA_*` 的数据值必须保留 `Hype/Magic/Mind/Money/Soul/Stamina`；显示译名与普通叙述词义分开。映射见项目风格指南。
- 每批用 `python tools/qa_series_names.py --row-id ID` 检查涉及条目，多个 ID 重复参数；全量命名排查才不加过滤。报告仅为候选，普通词、同名角色、昵称及刻意错名须结合上下文裁决，不作盲目替换。
- CSV 修改后运行 `python tools/validate_translation.py`。
- 生成运行时文件时，依次运行 `python tools/build_translation.py` 和 `python tools/validate_runtime_contracts.py`。安装前两类校验必须通过；实机日志出现 `FAILURE LOADING EVENTS` 时不得发布。
- 本工作流不自行触发游戏安装或发布；按用户实际任务范围执行。
