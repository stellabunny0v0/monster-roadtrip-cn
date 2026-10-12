from __future__ import annotations

import argparse
from pathlib import Path

from translation_common import extract_tokens, load_rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate translation CSV files")
    parser.add_argument("--translation", default=Path("translation"), type=Path)
    args = parser.parse_args()

    errors: list[str] = []
    rows = load_rows(args.translation)
    translated = 0
    for row_id, row in rows.items():
        target = row.get("target", "")
        if not target:
            continue
        translated += 1
        if "\t" in target or "\r" in target or "\n" in target:
            errors.append(f"{row_id}: target contains a literal tab or newline; use [n]")
        source_tokens = extract_tokens(row["source"])
        target_tokens = extract_tokens(target)
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

