"""Require reviewed Chinese names for every existing map/destination UI key."""
import json
import re
from pathlib import Path


def validate_location_names(translation_dir: Path, rows: dict, built_values: dict | None = None) -> list[str]:
    path = translation_dir / 'location_names_zh.json'
    places = {key.split(':', 1)[1]: row for key, row in rows.items()
              if key.startswith(('english_metatexts:RML_', 'english_metatexts:DTT_'))}
    # Standalone dialogue fixtures have no map UI and need no place manifest.
    if not places and not path.exists():
        return []
    try:
        names = json.loads(path.read_text(encoding='utf-8'))
    except (OSError, ValueError) as error:
        return [f'Location-name manifest unavailable: {error}']
    errors = []
    if set(names) != set(places):
        errors.append(f'Location-name coverage changed: {set(names) ^ set(places)}')
    for key, row in places.items():
        expected = names.get(key)
        if not isinstance(expected, str) or not re.search(r'[\u3400-\u9fff]', expected):
            errors.append(f'{key}: missing reviewed Chinese place name')
        if row['target'] != expected:
            errors.append(f'{key}: translation differs from reviewed place name')
        if built_values is not None and built_values.get(key) != expected:
            errors.append(f'{key}: built place name is missing, English or stale')
    return errors
