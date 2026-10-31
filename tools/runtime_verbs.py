"""Compile explicitly reviewed, row-specific Chinese verb expansions.

CSV and runtime event tables retain their original placeholders. The plugin
applies this sidecar only to an exact matching translated line, before the game
performs its English verb inflection. Other placeholders remain game-owned.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from translation_common import extract_tokens
from stat_contracts import compile_event_text

VERB = re.compile(r"%VERB(?:CAPS)?_[A-Za-z'_]+%")
MANIFEST_NAME = "schinese_verb_overrides.tsv"


def no_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate runtime verb override: {key}")
        result[key] = value
    return result


def compile_overrides(translation_dir: Path, rows: dict) -> list[tuple[str, str, str]]:
    path = translation_dir / "runtime_verb_overrides_zh.json"
    overrides = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=no_duplicate_keys)
    expected_ids = {key for key, row in rows.items() if VERB.search(row['source'])}
    if set(overrides) != expected_ids:
        raise ValueError(f"Verb override coverage mismatch: {set(overrides) ^ expected_ids}")
    result = []
    for key, replacements in overrides.items():
        row = rows[key]
        if not re.fullmatch(r"english_events_[a-z]+:L[1-9][0-9]*", key):
            raise ValueError(f"Invalid event row: {key}")
        target = compile_event_text(row['source'], row['target'], key)
        if not target or any(c in target for c in '\t\r\n'):
            raise ValueError(f"Invalid verb override text: {key}")
        if set(replacements) != set(VERB.findall(row['source'])) or set(replacements) != set(VERB.findall(target)):
            raise ValueError(f"Verb token mismatch: {key}")
        resolved = target
        for token, replacement in replacements.items():
            if not isinstance(replacement, str) or (replacement and not re.fullmatch(r'[\u3400-\u9fff]+', replacement)):
                raise ValueError(f"Verb replacement must be Chinese or empty: {key} {token}")
            resolved = resolved.replace(token, replacement)
        expected_tokens = extract_tokens(target)
        for token in replacements:
            del expected_tokens[token]
        if extract_tokens(resolved) != expected_tokens or VERB.search(resolved):
            raise ValueError(f"Non-verb token changed: {key}")
        result.append((key, target, resolved))
    return result


def build_overrides(translation_dir: Path, rows: dict, output_dir: Path) -> None:
    records = compile_overrides(translation_dir, rows)
    (output_dir / MANIFEST_NAME).write_text(
        ''.join('\t'.join(record) + '\n' for record in records), encoding='utf-8', newline='')


def validate_overrides(translation_dir: Path, rows: dict, output_dir: Path) -> list[str]:
    try:
        records = compile_overrides(translation_dir, rows)
        actual = (output_dir / MANIFEST_NAME).read_text(encoding='utf-8').splitlines()
        if actual != ['\t'.join(record) for record in records]:
            return ['Runtime verb sidecar is stale; rebuild translations']
        for key, target, _ in records:
            stem, number = key.rsplit(':L', 1)
            lines = (output_dir / (stem.replace('english_', 'schinese_', 1) + '.txt')).read_text(encoding='utf-8').splitlines()
            fields = lines[int(number)-1].split('\t')
            if len(fields) < 4 or fields[3] != target:
                return [f'Runtime verb sidecar does not match event text: {key}']
        return []
    except (ValueError, OSError, IndexError, KeyError, TypeError) as error:
        return [f'Runtime verb validation failed: {error}']
