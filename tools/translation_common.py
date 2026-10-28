from __future__ import annotations

import csv
import json
import re
from collections import Counter
from pathlib import Path


TOKEN_PATTERNS = (
    re.compile(r"%[A-Za-z0-9_']+%"),
    re.compile(r"\[[^\]\r\n]{1,80}\]"),
    re.compile(r"</?[^>\r\n]{1,100}>"),
    re.compile(r"\{[^}\r\n]{1,80}\}"),
)

FORMATTING_TOKEN = re.compile(
    r"\[(?:/?(?:n|b|i|u|s|c|sub|sup|url)|url=[^\]]*|\d+|[0-9a-f]{2}|[0-9a-f]{6}|[0-9a-f]{8})\]"
    r"|</?(?:b|i|u|s|color|size|font|sprite|quad|material|voffset|space)(?:[ =][^>]*)?>",
    re.IGNORECASE,
)


def extract_tokens(text: str, display_literals: frozenset[str] = frozenset()) -> Counter[str]:
    """Keep nested variables protected, even inside approved display-only wrappers."""
    tokens: Counter[str] = Counter()
    for pattern in TOKEN_PATTERNS:
        tokens.update(token for token in pattern.findall(text) if token not in display_literals)
    return tokens


def load_display_literal_overrides(translation_dir: Path) -> dict[str, list[dict[str, str]]]:
    path = translation_dir / "display_literal_overrides.json"
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


def row_display_literals(
    row: dict[str, str], overrides: dict[str, list[dict[str, str]]]
) -> frozenset[str]:
    """Only exact, documented source/target pairs for this row may bypass wrapper checks."""
    literals: set[str] = set()
    for pair in overrides.get(row["row_id"], []):
        source, target = pair["source"], pair["target"]
        if FORMATTING_TOKEN.fullmatch(source):
            raise ValueError(f"{row['row_id']}: formatting/control tokens cannot be display overrides")
        if not source or row["source"].count(source) != row["target"].count(target):
            raise ValueError(f"{row['row_id']}: approved display literal changed or is missing")
        if row["source"].count(source) == 0:
            raise ValueError(f"{row['row_id']}: approved display literal is absent from source")
        if (source[0], source[-1]) not in {("<", ">"), ("[", "]")}:
            raise ValueError(f"{row['row_id']}: invalid display literal wrapper")
        if not target or (source[0], source[-1]) != (target[0], target[-1]):
            raise ValueError(f"{row['row_id']}: display literal delimiters changed")
        if source != target and source in row["target"]:
            raise ValueError(f"{row['row_id']}: untranslated display literal duplicated in target")
        literals.update((source, target))
    return frozenset(literals)


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

