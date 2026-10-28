"""Build a read-only series-name review queue; never perform global replacements."""
from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter
from pathlib import Path

from translation_common import load_rows

ROOT = Path(__file__).resolve().parents[1]


def name_issues(source: str, target: str, entries: list[dict]) -> list[dict[str, str]]:
    issues = []
    canonical_spans = [(m.start(), m.end()) for term in entries
                       for m in re.finditer(re.escape(term['zh']), target)]
    for term in entries:
        # For example, 阿米 is an old Miri nickname but 阿米拉 is a valid Amira name.
        aliases = [alias for alias in term['avoid']
                   if any(not any(a <= m.start() and m.end() <= b for a, b in canonical_spans)
                          for m in re.finditer(re.escape(alias), target))]
        if not aliases:
            continue
        # Exact English casing avoids treating ordinary joy/hope/faith as names.
        # Even a source-name match is a candidate, not proof of referent identity.
        pattern = r'(?<![A-Za-z])' + re.escape(term['en']) + r'(?![A-Za-z])'
        matched = re.search(pattern, source) is not None
        issues.append(dict(en=term['en'], expected=term['zh'], found=' / '.join(aliases),
                           confidence='source-name-and-alias' if matched else 'context-required',
                           evidence='; '.join(term['evidence'])))
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--translation', type=Path, default=ROOT/'translation')
    parser.add_argument('--glossary', type=Path, default=ROOT/'docs/series-reference/glossary.json')
    parser.add_argument('--output', type=Path, default=ROOT/'analysis/series_name_review.csv')
    parser.add_argument('--row-id', action='append', help='Optional row IDs for the current review batch')
    args = parser.parse_args()
    entries = json.loads(args.glossary.read_text(encoding='utf-8'))['entries']
    selected = set(args.row_id or [])
    issues = []
    rows = load_rows(args.translation)
    missing = selected - rows.keys()
    if missing:
        parser.error('Unknown row IDs: ' + ', '.join(sorted(missing)))
    for row_id, row in rows.items():
        if selected and row_id not in selected:
            continue
        for issue in name_issues(row['source'], row.get('target', ''), entries):
            issues.append(dict(row_id=row_id, **issue, source=row['source'], target=row.get('target', '')))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['row_id','en','expected','found','confidence','evidence','source','target'])
        writer.writeheader()
        writer.writerows(issues)
    print(f'Name-review candidates: {len(issues)} in {len(set(x["row_id"] for x in issues))} rows')
    print(json.dumps(dict(Counter(x['en'] for x in issues)), ensure_ascii=False))
    print(f'Report: {args.output}')
    print('Read-only candidates; resolve referents in context. This is not a completeness or translation-quality check.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
