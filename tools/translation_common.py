from __future__ import annotations

import csv
import re
from collections import Counter
from pathlib import Path


TOKEN_PATTERNS = (
    re.compile(r"%[A-Za-z0-9_']+%"),
    re.compile(r"\[[^\]\r\n]{1,80}\]"),
    re.compile(r"</?[^>\r\n]{1,100}>"),
    re.compile(r"\{[^}\r\n]{1,80}\}"),
)


def extract_tokens(text: str) -> Counter[str]:
    tokens: Counter[str] = Counter()
    for pattern in TOKEN_PATTERNS:
        tokens.update(pattern.findall(text))
    return tokens


def load_rows(translation_dir: Path) -> dict[str, dict[str, str]]:
    rows: dict[str, dict[str, str]] = {}
    for csv_path in sorted(translation_dir.glob("english_*.csv")):
        with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
            for row in csv.DictReader(handle):
                row_id = row["row_id"]
                if row_id in rows:
                    raise ValueError(f"Duplicate row_id: {row_id}")
                rows[row_id] = row
    return rows

