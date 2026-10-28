# 本次接入范围

2026-10-13：已将用户提供的 Monster Prom 旧作文本整理为系列参考，并接入当前 Roadtrip 审校。

- 用户指定：Polly＝波莉，Liam＝李姆，Vera＝薇拉。Vera 的旧作正文异译“薇娜”只保留为证据，不作为本项目标准。
- [names.md](names.md) 与 [voice-and-style.md](voice-and-style.md) 是系列语言参考；合并后的 skill 只按本批人物与疑问检索，避免每批完整加载。人名表与 JSON 词表二选一。
- `translation/glossary.json` 更新／新增 39 个词条，包含 13 个旧词条改名，具体变化见 [glossary-migration.json](glossary-migration.json)。其他现有词条保留。
- `tools/qa_series_names.py` 新增只读命名候选扫描，支持用重复的 `--row-id` 限定本批范围。首次扫描得到 991 项提示，涉及 950 条不同译文。可能存在需要保留的普通词义或剧情别名，提示不等于确认错误。
- 本次接入没有批量改写翻译 CSV 或覆盖表；既有译文里的旧名字将随审校处理。历史 reviewed 状态和审校计数没有因词表变化自动提升或重置。
- 技术验证：新旧两个 skill 的结构验证通过；新脚本检查了人名冲突、正确名称、普通 hope、阿米／阿米拉子串等情况；30,255 条翻译记录的现有占位符验证通过。这不是全量语言质量验收或实机测试。

## 合并与精简（同日）

唯一使用入口为 `$monster-prom-series-zh`，已合并原 `$monster-roadtrip-zh-polish` 的编辑与校验流程；旧入口移出技能目录并保留备份。当前工作流见 [roadtrip.md](roadtrip.md)，项目风格指南只保留项目特有用语。相同上下文已读且未变的规则不重复加载；完整事件对白仍需阅读。

可复制提示词见 [reference-prompt.md](reference-prompt.md)，供其他模型单独使用，正常调用 skill 不额外加载。后续用户修改用名时，同步本目录的词表／说明、项目 `translation/glossary.json` 及个人 skill 的对应参考。证据文件保持旧作原文，不为适配新规范而篡改。
