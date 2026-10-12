from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path


CSV_FIELDS = [
    "row_id",
    "source_file",
    "source_line",
    "event_id",
    "speaker_or_key",
    "mood",
    "source",
    "target",
    "status",
    "notes",
]
META_RE = re.compile(
    r'^(?P<indent>\s*)"(?P<key>(?:\\.|[^"\\])*)"\s*:\s*'
    r'"(?P<value>(?:\\.|[^"\\])*)"(?P<comma>,?)'
)


def decode_json_string(value: str) -> str:
    return json.loads('"' + value + '"')


def read_existing(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return {row["row_id"]: row for row in csv.DictReader(handle)}


def load_seed(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def make_row(
    row_id: str,
    source_file: str,
    source_line: int,
    event_id: str,
    speaker_or_key: str,
    mood: str,
    source: str,
) -> dict[str, str]:
    return {
        "row_id": row_id,
        "source_file": source_file,
        "source_line": str(source_line),
        "event_id": event_id,
        "speaker_or_key": speaker_or_key,
        "mood": mood,
        "source": source,
        "target": "",
        "status": "todo",
        "notes": "",
    }


def parse_event_file(path: Path) -> list[dict[str, str]]:
    rows = []
    event_id = ""
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        fields = raw_line.split("\t")
        if fields and fields[0].strip().startswith(">>>"):
            nonempty = [item.strip() for item in fields if item.strip()]
            event_id = nonempty[1] if len(nonempty) > 1 else ""
            continue
        if len(fields) <= 3 or not fields[3]:
            continue
        speaker = fields[1].strip() if len(fields) > 1 else ""
        mood = fields[2].strip() if len(fields) > 2 else ""
        rows.append(
            make_row(
                f"{path.stem}:L{line_number}",
                path.name,
                line_number,
                event_id,
                speaker or fields[0].strip(),
                mood,
                fields[3],
            )
        )
    return rows


def parse_metatext_file(path: Path) -> list[dict[str, str]]:
    rows = []
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        match = META_RE.match(raw_line)
        if not match:
            continue
        key = decode_json_string(match.group("key"))
        value = decode_json_string(match.group("value"))
        rows.append(
            make_row(
                f"{path.stem}:{key}", path.name, line_number, "metatext", key, "", value
            )
        )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Create or refresh translation CSV files")
    parser.add_argument("--input", default=Path("extracted/original"), type=Path)
    parser.add_argument("--output", default=Path("translation"), type=Path)
    parser.add_argument("--seed", default=Path("translation/seed_zh.json"), type=Path)
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    seed = load_seed(args.seed)
    total = 0
    seeded = 0
    for source_path in sorted(args.input.glob("english_*")):
        if source_path.suffix == ".txt":
            rows = parse_event_file(source_path)
        elif source_path.suffix == ".json":
            rows = parse_metatext_file(source_path)
        else:
            continue

        csv_path = args.output / f"{source_path.stem}.csv"
        existing = read_existing(csv_path)
        for row in rows:
            previous = existing.get(row["row_id"])
            if previous:
                for field in ("target", "status", "notes"):
                    row[field] = previous.get(field, row[field])
            if not row["target"] and row["row_id"] in seed:
                row["target"] = seed[row["row_id"]]
                row["status"] = "draft"
                seeded += 1

        with csv_path.open("w", encoding="utf-8-sig", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=CSV_FIELDS)
            writer.writeheader()
            writer.writerows(rows)
        total += len(rows)
        print(f"{csv_path.name}: {len(rows)} rows")

    print(f"Prepared {total} translation rows ({seeded} seeded translations applied)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

