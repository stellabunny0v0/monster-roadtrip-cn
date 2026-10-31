from __future__ import annotations

import argparse
from pathlib import Path

from translation_common import extract_tokens, load_rows, load_display_literal_overrides, row_display_literals
from stat_contracts import compile_event_text
from location_contracts import validate_location_names


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate translation CSV files")
    parser.add_argument("--translation", default=Path("translation"), type=Path)
    args = parser.parse_args()

    errors: list[str] = []
    rows = load_rows(args.translation)
    errors.extend(validate_location_names(args.translation, rows))
    display_overrides = load_display_literal_overrides(args.translation)
    for row_id in display_overrides:
        if row_id not in rows:
            errors.append(f"{row_id}: unknown row in display literal overrides")
    translated = 0
    for row_id, row in rows.items():
        target = row.get("target", "")
        if not target:
            if row_id in display_overrides:
                errors.append(f"{row_id}: approved display literal target is missing")
            continue
        translated += 1
        if row_id.startswith('english_events_'):
            try:
                compile_event_text(row['source'], target, row_id)
            except ValueError as error:
                errors.append(str(error))
        if "\t" in target or "\r" in target or "\n" in target:
            errors.append(f"{row_id}: target contains a literal tab or newline; use [n]")
        try:
            literals = row_display_literals(row, display_overrides)
        except ValueError as error:
            errors.append(str(error))
            continue
        source_tokens = extract_tokens(row["source"], literals)
        target_tokens = extract_tokens(target, literals)
        if source_tokens != target_tokens:
            errors.append(
                f"{row_id}: placeholder mismatch: source={dict(source_tokens)}, "
                f"target={dict(target_tokens)}"
            )

    print(f"Rows: {len(rows)}; translated: {translated}; remaining: {len(rows) - translated}")
    if errors:
        print(f"Validation failed with {len(errors)} error(s):")
        for error in errors[:100]:
            print(f"  - {error}")
        if len(errors) > 100:
            print(f"  ... and {len(errors) - 100} more")
        return 1
    print("Validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

