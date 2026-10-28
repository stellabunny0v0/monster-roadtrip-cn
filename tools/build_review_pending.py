"""Export the current unresolved review entries with their full bilingual text."""
import csv
import json
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[1]
    progress = json.loads((root / 'docs/review/progress.json').read_text(encoding='utf-8'))
    rows = {}
    for path in sorted((root / 'translation').glob('english_*.csv')):
        with path.open(encoding='utf-8-sig', newline='') as handle:
            for row in csv.DictReader(handle):
                assert row['row_id'] not in rows, row['row_id']
                rows[row['row_id']] = row
    flags = progress['flagged_entries']
    assert len(flags) == len(set(flags))
    runtime_holds = progress.get('runtime_verb_hold_entries', [])
    ids = list(dict.fromkeys(flags + runtime_holds))
    extra_holds = len(set(runtime_holds) - set(flags))
    out = [
        '# 待核译文（完整中英对照）', '',
        f'当前共 {len(ids)} 条：{len(flags)} 条 REVIEW 译文待核，另有 {extra_holds} 条历史语言审校已记录、但运行时问题尚未解决的条目。每条直接列出英文原句、当前中文译文和现有待核备注。',
        ('待核不等于未阅读；这些条目已检查，但尚有语义、双关、称名或运行时变量问题。'
         if ids else '当前没有尚待裁决的语言疑难项。'),
        '语言定稿、运行时适配与实机验收分别记录；源码中的变量保留不等于运行时仍输出英文。',
        '可按事件名、人物或英文关键词搜索。重新生成命令：`python tools/build_review_pending.py`。', '',
    ]
    if progress.get('pending_review_109'):
        out += [
            '## 本轮审校结果', '',
            '原清单 109 条已逐条审校：56 条 KEEP、25 条 FIX、28 条 POLISH。'
            '完整原文、修改前后译文、展开后文本及理由见 [109 条审校记录](pending-review-109.md)'
            '与 [CSV 明细](pending-review-109.csv)。', '',
        ]
        checks = progress.get('runtime_verb_ingame_pending_entries', [])
        if checks:
            out += [
                f'{len(checks)} 条动词变量已通过按行中文展开适配及离线验证，'
                '仍待游戏内验收；这不再属于未裁决的翻译疑难。'
                '未标记任何条目为 `ingame-ok`。', '',
                '加载适配必须配合 0.3.3 或更高版本插件与同批次的 '
                '`schinese_verb_overrides.tsv` 使用。', '',
            ]
    for i, key in enumerate(ids, 1):
        row = rows[key]
        notes = row.get('notes', '').strip()
        if '; ' in notes:
            notes = notes.split('; ', 1)[1]
        if not notes or notes.endswith('REVIEW'):
            notes = '原审校记录标记为 REVIEW；具体争议需结合对应事件及批次记录核实。'
        if key in runtime_holds:
            runtime_note = '英文动词变量仍会在运行时展开为英文；须核查并修复中文展开，当前不视为已实机解决。'
            notes = runtime_note if key not in flags else notes + ' ' + runtime_note
        # Fences preserve literal variable/tag text without interpreting HTML or Markdown.
        fence = '~~~~'
        while fence in row['source'] or fence in row['target']:
            fence += '~'
        out += [
            f'## {i}. {key}', '',
            f"事件：`{row['event_id']}`；说话人／键：`{row['speaker_or_key']}`", '',
            '**英文原句**', '', fence + 'text', row['source'], fence, '',
            '**当前中文译文**', '', fence + 'text', row['target'], fence, '',
            '**待核原因／原备注**：' + notes, '',
        ]
    path = root / 'docs/review/PENDING.md'
    path.write_text('\n'.join(out) + '\n', encoding='utf-8')
    print(f'Exported {len(ids)} bilingual pending entries: {path}')


if __name__ == '__main__':
    main()
