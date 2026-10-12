from __future__ import annotations

import argparse
import csv
import re
from collections import defaultdict
from pathlib import Path

from translation_common import extract_tokens, load_rows


CJK = re.compile(r"[\u4e00-\u9fff]")
PRIVATE_USE = re.compile(r"[\ue000-\uf8ff]")
# U+30FB KATAKANA MIDDLE DOT is also commonly used between transliterated names in
# Chinese, so it is intentionally excluded from the Japanese-script check.
FOREIGN_SCRIPT = re.compile(
    r"[\u3040-\u30fa\u30fc-\u30ff\uac00-\ud7af\u0400-\u04ff\u0600-\u06ff]"
)
ASCII_WORDS = re.compile(r"[A-Za-z]{3,}")
SUSPICIOUS = re.compile(
    r"\\fn|\\fs\d|\\bord|\\shad|original content|content archived|原始内容存档|wikipedia|https?://",
    re.IGNORECASE,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a review queue for Chinese translations")
    parser.add_argument("--translation", default=Path("translation"), type=Path)
    parser.add_argument("--output", default=Path("analysis/translation_qa.csv"), type=Path)
    args = parser.parse_args()

    rows = load_rows(args.translation)
    issues: list[dict[str, str]] = []
    by_source: dict[str, set[str]] = defaultdict(set)
    for row_id, row in rows.items():
        source = row["source"]
        target = row.get("target", "")
        if not target:
            issues.append({"row_id": row_id, "issue": "untranslated", "source": source, "target": ""})
            continue
        by_source[source].add(target)
        reasons: list[str] = []
        if extract_tokens(source) != extract_tokens(target):
            reasons.append("placeholder mismatch")
        if PRIVATE_USE.search(target):
            reasons.append("private-use character")
        if FOREIGN_SCRIPT.search(target):
            reasons.append("unexpected foreign script")
        if SUSPICIOUS.search(target):
            reasons.append("suspicious generated phrase or formatting")
        if re.search(r"[A-Za-z]", source) and not CJK.search(target) and source != target:
            reasons.append("no Chinese characters")
        if len(source) >= 12:
            ratio = len(target) / len(source)
            if ratio > 2.5:
                reasons.append("translation unusually long")
            elif ratio < 0.08:
                reasons.append("translation unusually short")
        if len(ASCII_WORDS.findall(target)) >= 4:
            reasons.append("many untranslated English words")
        if reasons:
            issues.append(
                {"row_id": row_id, "issue": "; ".join(reasons), "source": source, "target": target}
            )

    for source, targets in by_source.items():
        if len(targets) <= 1:
            continue
        for row_id, row in rows.items():
            if row["source"] == source:
                issues.append(
                    {
                        "row_id": row_id,
                        "issue": "duplicate source has inconsistent translations",
                        "source": source,
                        "target": row.get("target", ""),
                    }
                )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["row_id", "issue", "source", "target"])
        writer.writeheader()
        writer.writerows(issues)
    print(f"QA report: {args.output} ({len(issues)} issue row(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
