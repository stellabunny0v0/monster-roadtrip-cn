from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from translation_common import load_rows
from runtime_verbs import build_overrides
from stat_contracts import compile_event_text


META_RE = re.compile(
    r'^(?P<indent>\s*)"(?P<key>(?:\\.|[^"\\])*)"(?P<between>\s*:\s*)'
    r'"(?P<value>(?:\\.|[^"\\])*)"(?P<rest>,?.*)$'
)


def decode_json_string(value: str) -> str:
    return json.loads('"' + value + '"')


def encode_json_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)[1:-1]


def build_event(source_path: Path, destination: Path, rows: dict[str, dict[str, str]]) -> None:
    output = []
    for line_number, raw_line in enumerate(source_path.read_text(encoding="utf-8-sig").splitlines(), 1):
        fields = raw_line.split("\t")
        row = rows.get(f"{source_path.stem}:L{line_number}")
        if row and row.get("target"):
            if len(fields) <= 3:
                raise ValueError(f"Cannot replace text at {source_path.name}:{line_number}")
            fields[3] = compile_event_text(row["source"], row["target"], row["row_id"])
            raw_line = "\t".join(fields)
        output.append(raw_line)
    destination.write_text("\r\n".join(output) + "\r\n", encoding="utf-8", newline="")


def build_metatext(source_path: Path, destination: Path, rows: dict[str, dict[str, str]]) -> None:
    output = []
    for raw_line in source_path.read_text(encoding="utf-8-sig").splitlines():
        match = META_RE.match(raw_line)
        if match:
            key = decode_json_string(match.group("key"))
            row = rows.get(f"{source_path.stem}:{key}")
            if row and row.get("target"):
                raw_line = (
                    match.group("indent")
                    + '"'
                    + match.group("key")
                    + '"'
                    + match.group("between")
                    + '"'
                    + encode_json_string(row["target"])
                    + '"'
                    + match.group("rest")
                )
        output.append(raw_line)
    destination.write_text("\r\n".join(output) + "\r\n", encoding="utf-8", newline="")


def main() -> int:
    parser = argparse.ArgumentParser(description="Build runtime Chinese localization files")
    parser.add_argument("--source", default=Path("extracted/original"), type=Path)
    parser.add_argument("--translation", default=Path("translation"), type=Path)
    parser.add_argument(
        "--output",
        default=Path("build/package/BepInEx/plugins/MonsterRoadtripChinese/Translation"),
        type=Path,
    )
    args = parser.parse_args()

    rows = load_rows(args.translation)
    args.output.mkdir(parents=True, exist_ok=True)
    built = 0
    for source_path in sorted(args.source.glob("english_*")):
        destination_name = source_path.name.replace("english_", "schinese_", 1)
        destination = args.output / destination_name
        if source_path.suffix == ".txt":
            build_event(source_path, destination, rows)
        elif source_path.suffix == ".json":
            build_metatext(source_path, destination, rows)
        else:
            continue
        print(f"Built {destination}")
        built += 1
    build_overrides(args.translation, rows, args.output)
    print(f"Built {built} localization files and reviewed Chinese verb sidecar")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

