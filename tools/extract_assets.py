from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

import UnityPy


TEXT_BUNDLE = Path(
    "MonsterRoadtrip_Data/StreamingAssets/aa/StandaloneWindows/texts_assets_all.bundle"
)
LANGUAGE_BUNDLE = Path(
    "MonsterRoadtrip_Data/StreamingAssets/aa/StandaloneWindows/"
    "profileslanguages_assets_all.bundle"
)
CATALOG = Path("MonsterRoadtrip_Data/StreamingAssets/aa/catalog.json")
ASSEMBLY = Path("MonsterRoadtrip_Data/Managed/Assembly-CSharp.dll")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def script_bytes(value: object) -> bytes:
    if isinstance(value, bytes):
        return value
    if isinstance(value, str):
        return value.encode("utf-8")
    raise TypeError(f"Unsupported TextAsset script value: {type(value)!r}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract Monster Roadtrip localization assets")
    parser.add_argument("--game-dir", required=True, type=Path)
    parser.add_argument("--output", default=Path("extracted"), type=Path)
    args = parser.parse_args()

    game_dir = args.game_dir.resolve()
    output_dir = args.output.resolve()
    original_dir = output_dir / "original"
    original_dir.mkdir(parents=True, exist_ok=True)

    required = [TEXT_BUNDLE, LANGUAGE_BUNDLE, CATALOG, ASSEMBLY]
    missing = [str(game_dir / item) for item in required if not (game_dir / item).is_file()]
    if missing:
        print("Missing required game files:", file=sys.stderr)
        print("\n".join(missing), file=sys.stderr)
        return 2

    text_env = UnityPy.load(str(game_dir / TEXT_BUNDLE))
    extracted = []
    for obj in text_env.objects:
        if obj.type.name != "TextAsset":
            continue
        asset = obj.read()
        name = asset.m_Name
        extension = ".json" if name.endswith("metatexts") else ".txt"
        destination = original_dir / f"{name}{extension}"
        data = script_bytes(asset.m_Script)
        destination.write_bytes(data)
        extracted.append(
            {
                "name": name,
                "file": destination.name,
                "path_id": obj.path_id,
                "bytes": len(data),
                "sha256": hashlib.sha256(data).hexdigest().upper(),
            }
        )

    language_env = UnityPy.load(str(game_dir / LANGUAGE_BUNDLE))
    profiles = []
    for obj in language_env.objects:
        if obj.type.name != "MonoBehaviour":
            continue
        tree = obj.read_typetree()
        if str(tree.get("m_Name", "")).startswith("language_"):
            tree["path_id"] = obj.path_id
            profiles.append(tree)

    manifest = {
        "game_directory": str(game_dir),
        "unity_version": "2021.3.15f1",
        "architecture": "win-x86",
        "files": {
            str(item).replace("\\", "/"): {
                "bytes": (game_dir / item).stat().st_size,
                "sha256": sha256(game_dir / item),
            }
            for item in required
        },
        "text_assets": sorted(extracted, key=lambda item: item["name"]),
        "language_profiles": profiles,
    }
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Extracted {len(extracted)} text assets to {original_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

