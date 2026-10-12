from __future__ import annotations

import argparse
import csv
import os
import re
from collections import Counter
from pathlib import Path

from translation_common import TOKEN_PATTERNS, extract_tokens


PRIVATE_USE = re.compile(r"[\ue000-\uf8ff]")
FOREIGN_SCRIPT = re.compile(
    r"[\u3040-\u30fa\u30fc-\u30ff\uac00-\ud7af\u0400-\u04ff\u0600-\u06ff]"
)
HALLUCINATED_ARCHIVE_TEXT = re.compile(
    r"\s*(?:"
    r"\(原始内容存档于\d{4}-\d{2}-\d{2}\)\.?(?:\s*\([^)]*语\)\.?)?"
    r"|互联网档案馆的存檔,存档日期\d{4}-\d{2}-\d{2}\."
    r"|页面存档备份,存于互联网档案馆\."
    r"|\((?:中文\(简体\)|美国英语|英语)\)\."
    r")"
)


def unwrap_or_remove(token: str) -> str:
    if token.startswith("[") and token.endswith("]"):
        return token[1:-1]
    return ""


def repair(source: str, target: str) -> tuple[str, bool]:
    original_target = target
    changed = False
    source_tokens = extract_tokens(source)
    target_tokens = extract_tokens(target)
    extras = target_tokens - source_tokens
    for token, count in extras.items():
        for _ in range(count):
            target = target.replace(token, unwrap_or_remove(token), 1)
            changed = True
    if PRIVATE_USE.search(target):
        target = PRIVATE_USE.sub("", target)
        changed = True
    cleaned = HALLUCINATED_ARCHIVE_TEXT.sub("", target)
    if cleaned != target:
        target = cleaned
        changed = True
    fixed = target
    replacements = (
        ("珃瓳", "哇哦"),
        ("瓳瓳", "哦哦"),
        ("瓳摆", "天啊"),
        ("瓳", "哦"),
        ("糑", "嘿"),
        ("cmи", "你和"),
        ("瓳и笵", "哦，我知道"),
        ("иぃ笵", "我不知道"),
        ("и稱钩", "我只能想象"),
        ("и痷琌", "我的真名是"),
        ("и琌...", "我是"),
        ("и琌", "我是"),
        ("и惠璶硂", "我需要这个"),
        ("ぱ摆", "天啊"),
        ("赣и", "可恶，"),
        ("и笵", "我知道"),
        ("и...", "我……"),
    )
    for bad, good in replacements:
        fixed = fixed.replace(bad, good)
    fixed = FOREIGN_SCRIPT.sub("", fixed)
    if fixed != target:
        target = fixed
        changed = True
    target = target.strip()
    return target, target != original_target


def main() -> int:
    parser = argparse.ArgumentParser(description="Remove tokens hallucinated by machine translation")
    parser.add_argument("--translation", default=Path("translation"), type=Path)
    args = parser.parse_args()
    repaired = 0
    for csv_path in sorted(args.translation.glob("english_*.csv")):
        with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            fieldnames = reader.fieldnames
            rows = list(reader)
        if fieldnames is None:
            raise ValueError(f"Missing CSV header: {csv_path}")
        changed_file = False
        for row in rows:
            if row.get("status") != "machine" or not row.get("target"):
                continue
            row["target"], changed = repair(row["source"], row["target"])
            if (
                row["row_id"].startswith("english_metatexts:XTR_CRE_")
                and row["source"].startswith("Crowd Designers")
            ):
                desired = row["source"].replace("Crowd Designers", "众筹设计者", 1)
                if row["target"] != desired:
                    row["target"] = desired
                    changed = True
            if changed:
                row["notes"] = (row.get("notes", "") + "; sanitized").strip("; ")
                repaired += 1
                changed_file = True
        if changed_file:
            temporary = csv_path.with_suffix(csv_path.suffix + ".tmp")
            with temporary.open("w", encoding="utf-8-sig", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(rows)
            os.replace(temporary, csv_path)
    print(f"Sanitized {repaired} machine-translated row(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
