# 所有格变量定点核对

`CoreTextManager.GetPronounTypeId` 将 HisHer 映射为 HIS，随后按 pronoun base 拼出 `PRN_HIS_HEE/SHE/THY`。`CoreEventManager.GetPronounText` 直接取得该译文。现行系统表分别为“他的／她的／TA的”，所以正文不要再紧接一个“的”。

对已经逐句审校的所有含 `%HISHER%` 行，对照完整句子核对，发现本轮 5 行重复。修改见 `pronoun-runtime-fixes-001.csv`，已同步当前批次的最终译文记录与覆盖表。所有变量保持不变，原有 VERB 待办仍保留 draft；不增加首次审校数量，不称实机验证。后续正文按这一实际展开值继续安排中文语序。
