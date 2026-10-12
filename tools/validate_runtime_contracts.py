from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


# These values double as parser identifiers. Translating them makes every stat
# gain/loss line fail to load even though the JSON itself remains valid.
PARSER_STAT_KEYS = {
    "STA_HYPE": "Hype",
    "STA_MAGIC": "Magic",
    "STA_MIND": "Mind",
    "STA_MONEY": "Money",
    "STA_SOUL": "Soul",
    "STA_STAMINA": "Stamina",
}


def validate_events(source_dir: Path, output_dir: Path) -> list[str]:
    errors: list[str] = []
    for source_path in sorted(source_dir.glob("english_events_*.txt")):
        built_path = output_dir / source_path.name.replace("english_", "schinese_", 1)
        if not built_path.exists():
            errors.append(f"missing built event file: {built_path}")
            continue

        source_lines = source_path.read_text(encoding="utf-8-sig").splitlines()
        built_lines = built_path.read_text(encoding="utf-8-sig").splitlines()
        if len(source_lines) != len(built_lines):
            errors.append(
                f"{built_path.name}: line count changed "
                f"({len(source_lines)} -> {len(built_lines)})"
            )
            continue

        for line_number, (source_line, built_line) in enumerate(
            zip(source_lines, built_lines), 1
        ):
            source_fields = source_line.split("\t")
            built_fields = built_line.split("\t")
            if len(source_fields) != len(built_fields):
                errors.append(
                    f"{built_path.name}:{line_number}: tab field count changed "
                    f"({len(source_fields)} -> {len(built_fields)})"
                )
                continue
            for field_index, (source_field, built_field) in enumerate(
                zip(source_fields, built_fields)
            ):
                if field_index == 3 and len(source_fields) > 3:
                    continue
                if source_field != built_field:
                    errors.append(
                        f"{built_path.name}:{line_number}: control field "
                        f"{field_index} changed"
                    )
    return errors


def validate_metatexts(output_dir: Path) -> list[str]:
    errors: list[str] = []
    built_path = output_dir / "schinese_metatexts.json"
    if not built_path.exists():
        return [f"missing built metatext file: {built_path}"]
    try:
        relaxed_json = built_path.read_text(encoding="utf-8-sig")
        relaxed_json = re.sub(r"(?m)^\s*//.*$", "", relaxed_json)
        relaxed_json = re.sub(r",\s*([}\]])", r"\1", relaxed_json)
        documents = json.loads(relaxed_json)
        values = {}
        for document in documents:
            values.update(document)
    except (OSError, json.JSONDecodeError) as exception:
        return [f"{built_path.name}: invalid JSON: {exception}"]

    for key, expected in PARSER_STAT_KEYS.items():
        actual = values.get(key)
        if actual != expected:
            errors.append(
                f"{built_path.name}:{key}: parser identifier must stay "
                f"{expected!r}, got {actual!r}"
            )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate runtime-sensitive localization file structure"
    )
    parser.add_argument("--source", default=Path("extracted/original"), type=Path)
    parser.add_argument(
        "--output",
        default=Path("build/package/BepInEx/plugins/MonsterRoadtripChinese/Translation"),
        type=Path,
    )
    args = parser.parse_args()

    errors = validate_events(args.source, args.output)
    errors.extend(validate_metatexts(args.output))
    if errors:
        print(f"Runtime contract validation failed with {len(errors)} error(s):")
        for error in errors[:100]:
            print(f"  - {error}")
        if len(errors) > 100:
            print(f"  ... and {len(errors) - 100} more")
        return 1
    print("Runtime contract validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
