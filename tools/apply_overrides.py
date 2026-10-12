from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply authoritative human translation overrides")
    parser.add_argument("--translation", default=Path("translation"), type=Path)
    parser.add_argument(
        "--overrides",
        nargs="+",
        default=[
            Path("translation/seed_zh.json"),
            Path("translation/quality_overrides_zh.json"),
        ],
        type=Path,
    )
    args = parser.parse_args()

    overrides: dict[str, str] = {}
    for override_path in args.overrides:
        values = json.loads(override_path.read_text(encoding="utf-8"))
        duplicates = set(overrides) & set(values)
        if duplicates:
            raise ValueError(
                f"Duplicate overrides in {override_path}: " + ", ".join(sorted(duplicates))
            )
        overrides.update(values)
    applied = 0
    missing = set(overrides)
    for csv_path in sorted(args.translation.glob("english_*.csv")):
        with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            fieldnames = reader.fieldnames
            rows = list(reader)
        if fieldnames is None:
            raise ValueError(f"Missing CSV header: {csv_path}")
        changed = False
        for row in rows:
            row_id = row["row_id"]
            if row_id not in overrides:
                continue
            row["target"] = overrides[row_id]
            row["status"] = "reviewed"
            row["notes"] = "human override"
            missing.discard(row_id)
            applied += 1
            changed = True
        if changed:
            temporary = csv_path.with_suffix(csv_path.suffix + ".tmp")
            with temporary.open("w", encoding="utf-8-sig", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(rows)
            os.replace(temporary, csv_path)

    if missing:
        raise ValueError("Unknown override row IDs: " + ", ".join(sorted(missing)))
    print(f"Applied {applied} human overrides")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
