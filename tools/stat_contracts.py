"""Keep game-executable stat cues separate from their Chinese display names."""
from __future__ import annotations

import re

STAT_NAMES = {
    'HYPE': '热度', 'MAGIC': '魔力', 'MIND': '头脑',
    'MONEY': '金钱', 'SOUL': '灵魂', 'STAMINA': '体力',
}
CHINESE_STATS = {value: key for key, value in STAT_NAMES.items()}
# RegexUtils.GetRegexStatAny: the final non-word character is consumed.
GAME_STAT = re.compile(r'([+-])(N?)(\d+)\s*([A-Z\s]*[A-Z]+)(\W|$)')
EDITABLE_STAT = re.compile(
    r'([+-]N?\d+)\s*(' + '|'.join(CHINESE_STATS) +
    r'|HYPE|MAGIC|MIND|MONEY|SOUL|STAMINA)(?![A-Za-z])')
MISSION_CUE = '+XX PRANK DOLLARZ'
EDITABLE_MISSION = re.compile(r'\+XX\s*(?:PRANK DOLLARZ|恶作剧币)')


def stat_cues(text: str) -> list[tuple[str, str]]:
    """Cues the game's own regex and StatType enum can actually recognize."""
    return [(m[1] + m[2] + m[3], m[4].strip()) for m in GAME_STAT.finditer(text)
            if m[4].strip() in STAT_NAMES]


def validate_stat_text(source: str, built: str, row_id: str = '') -> None:
    if stat_cues(source) != stat_cues(built):
        raise ValueError(f'{row_id}: executable stat cues changed: '
                         f'{stat_cues(source)} -> {stat_cues(built)}')
    if source.count(MISSION_CUE) != built.count(MISSION_CUE):
        raise ValueError(f'{row_id}: executable Prank Dollarz cue changed')


def compile_event_text(source: str, target: str, row_id: str = '') -> str:
    def restore(match: re.Match) -> str:
        name = CHINESE_STATS.get(match[2], match[2])
        # Chinese letters count as \w in .NET. An ASCII separator is needed
        # when the following prose is attached to the executable English name.
        following = target[match.end():match.end() + 1]
        separator = ' ' if following and re.match(r'\w', following) else ''
        return match[1] + ' ' + name + separator

    built = EDITABLE_STAT.sub(restore, target)
    built = EDITABLE_MISSION.sub(MISSION_CUE, built)
    validate_stat_text(source, built, row_id)
    return built
