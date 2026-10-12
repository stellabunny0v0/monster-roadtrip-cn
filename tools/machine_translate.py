from __future__ import annotations

import argparse
import csv
import json
import os
import re
from pathlib import Path

import ctranslate2
import sentencepiece as spm

from sanitize_machine_translation import repair


TOKEN_PATTERN = re.compile(
    r"(%[A-Za-z0-9_']+%|\[[^\]\r\n]{1,80}\]|</?[^>\r\n]{1,100}>|\{[^}\r\n]{1,80}\})"
)
ASCII_WORD = re.compile(r"[A-Za-z]")
SENTENCE_BOUNDARY = re.compile(r"(?<=[.!?])(?=\s+)")


class OfflineTranslator:
    def __init__(
        self,
        model_dir: Path,
        glossary: dict[str, str],
        batch_size: int,
        beam_size: int,
        repetition_penalty: float,
        no_repeat_ngram_size: int,
    ) -> None:
        self.glossary = glossary
        self.batch_size = batch_size
        self.beam_size = beam_size
        self.repetition_penalty = repetition_penalty
        self.no_repeat_ngram_size = no_repeat_ngram_size
        self.processor = spm.SentencePieceProcessor(
            model_file=str(model_dir / "sentencepiece.model")
        )
        self.translator = ctranslate2.Translator(
            str(model_dir / "model"), device="cpu", compute_type="int8"
        )
        protected = sorted(glossary, key=len, reverse=True)
        parts = [TOKEN_PATTERN.pattern[1:-1]]
        parts.extend(re.escape(term) for term in protected)
        self.protected_pattern = re.compile("(" + "|".join(parts) + ")")

    @staticmethod
    def _chunk_plain_text(text: str, max_chars: int = 360) -> list[str]:
        chunks: list[str] = []
        for sentence in SENTENCE_BOUNDARY.split(text):
            if len(sentence) <= max_chars:
                chunks.append(sentence)
                continue
            remaining = sentence
            while len(remaining) > max_chars:
                split_at = remaining.rfind(" ", 0, max_chars + 1)
                if split_at < max_chars // 2:
                    split_at = max_chars
                chunks.append(remaining[:split_at])
                remaining = remaining[split_at:]
            if remaining:
                chunks.append(remaining)
        return chunks

    def split(self, text: str) -> list[tuple[str, str]]:
        result: list[tuple[str, str]] = []
        for part in self.protected_pattern.split(text):
            if not part:
                continue
            if TOKEN_PATTERN.fullmatch(part):
                result.append(("literal", part))
            elif part in self.glossary:
                result.append(("literal", self.glossary[part]))
            else:
                for chunk in self._chunk_plain_text(part):
                    leading = chunk[: len(chunk) - len(chunk.lstrip())]
                    trailing = chunk[len(chunk.rstrip()) :]
                    core = chunk.strip()
                    if leading:
                        result.append(("literal", leading))
                    if core:
                        kind = "translate" if ASCII_WORD.search(core) else "literal"
                        result.append((kind, core))
                    if trailing:
                        result.append(("literal", trailing))
        return result

    def translate_many(
        self, sources: list[str], cache: dict[str, str], checkpoint
    ) -> dict[str, list[tuple[str, str]]]:
        layouts = {source: self.split(source) for source in sources}
        pending: list[str] = []
        seen: set[str] = set()
        for layout in layouts.values():
            for kind, value in layout:
                if kind == "translate" and value not in cache and value not in seen:
                    pending.append(value)
                    seen.add(value)

        total = len(pending)
        for offset in range(0, total, self.batch_size):
            batch = pending[offset : offset + self.batch_size]
            tokenized = [self.processor.encode(item, out_type=str) for item in batch]
            results = self.translator.translate_batch(
                tokenized,
                beam_size=self.beam_size,
                repetition_penalty=self.repetition_penalty,
                no_repeat_ngram_size=self.no_repeat_ngram_size,
                max_batch_size=self.batch_size,
                batch_type="tokens",
                replace_unknowns=True,
            )
            for source, result in zip(batch, results):
                translated = self.processor.decode_pieces(result.hypotheses[0])
                cache[source] = translated.replace("▁", " ").replace("_", " ").strip()
            done = min(offset + len(batch), total)
            print(f"Machine translation: {done}/{total}", flush=True)
            checkpoint(cache)
        return layouts


def load_cache(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def save_cache(path: Path, cache: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    os.replace(temporary, path)


def translate_csv(
    csv_path: Path,
    translator: OfflineTranslator,
    cache: dict[str, str],
    cache_path: Path,
    limit: int | None,
    row_ids: set[str] | None,
    force: bool,
) -> int:
    with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        fieldnames = reader.fieldnames
        rows = list(reader)
    if fieldnames is None:
        raise ValueError(f"Missing CSV header: {csv_path}")

    if row_ids is None:
        pending_rows = [row for row in rows if not row.get("target") and row.get("source")]
    else:
        pending_rows = [
            row for row in rows if row["row_id"] in row_ids and row.get("source")
        ]
    if limit is not None:
        pending_rows = pending_rows[:limit]
    sources = list(dict.fromkeys(row["source"] for row in pending_rows))
    if force:
        for source in sources:
            for kind, value in translator.split(source):
                if kind == "translate":
                    cache.pop(value, None)
    layouts = translator.translate_many(
        sources, cache, lambda current: save_cache(cache_path, current)
    )

    translated_count = 0
    for row in pending_rows:
        output: list[str] = []
        for kind, value in layouts[row["source"]]:
            output.append(cache[value] if kind == "translate" else value)
        row["target"], sanitized = repair(row["source"], "".join(output))
        row["status"] = "machine"
        row["notes"] = "Argos en_zh 1.9; requires review"
        if sanitized:
            row["notes"] += "; sanitized"
        translated_count += 1

    temporary = csv_path.with_suffix(csv_path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    os.replace(temporary, csv_path)
    save_cache(cache_path, cache)
    print(f"Updated {csv_path}: {translated_count} row(s)")
    return translated_count


def main() -> int:
    parser = argparse.ArgumentParser(description="Create an offline machine-translation draft")
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--model-dir", required=True, type=Path)
    parser.add_argument("--glossary", default=Path("translation/glossary.json"), type=Path)
    parser.add_argument("--cache", default=Path(".cache/machine_translation_en_zh.json"), type=Path)
    parser.add_argument("--batch-size", default=64, type=int)
    parser.add_argument("--beam-size", default=2, type=int)
    parser.add_argument("--repetition-penalty", default=1.0, type=float)
    parser.add_argument("--no-repeat-ngram-size", default=0, type=int)
    parser.add_argument("--limit", type=int)
    parser.add_argument(
        "--row-ids",
        type=Path,
        help="CSV containing row_id values to retranslate even when targets are populated",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="discard cached translations for selected text before translating",
    )
    args = parser.parse_args()

    glossary = json.loads(args.glossary.read_text(encoding="utf-8"))
    cache = load_cache(args.cache)
    translator = OfflineTranslator(
        args.model_dir,
        glossary,
        args.batch_size,
        args.beam_size,
        args.repetition_penalty,
        args.no_repeat_ngram_size,
    )
    row_ids: set[str] | None = None
    if args.row_ids:
        with args.row_ids.open("r", encoding="utf-8-sig", newline="") as handle:
            row_ids = {row["row_id"] for row in csv.DictReader(handle)}
    total = 0
    for csv_path in args.files:
        total += translate_csv(
            csv_path, translator, cache, args.cache, args.limit, row_ids, args.force
        )
    print(f"Machine-translated rows: {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
