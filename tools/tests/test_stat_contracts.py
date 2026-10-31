import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from stat_contracts import compile_event_text, stat_cues, validate_stat_text


class StatContractsTests(unittest.TestCase):
    def test_chinese_names_compile_to_all_six_executable_stats(self):
        source = '+N2 HYPE, -N3 MAGIC, +4 MIND, -5 MONEY, +N6 SOUL, -7 STAMINA!'
        target = '+N2 热度，-N3 魔力，+4 头脑，-5 金钱，+N6 灵魂，-7 体力！'
        built = compile_event_text(source, target)
        self.assertEqual(stat_cues(source), stat_cues(built))
        self.assertIn('+N2 HYPE', built)
        self.assertIn('-7 STAMINA', built)

    def test_dotnet_word_boundary_before_chinese_prose(self):
        for target in ['获得 +N2 头脑的奖励。', '获得 +N2 MIND的奖励。']:
            built = compile_event_text('gain +N2 MIND.', target)
            self.assertIn('+N2 MIND 的', built)
            self.assertEqual(stat_cues(built), [('+N2', 'MIND')])
        self.assertEqual(stat_cues('+N2 MIND的奖励'), [])

    def test_refuses_sign_factor_stat_count_or_order_changes(self):
        for target in ['+N2 头脑', '-2 魔力', '-N3 魔力', '-N2 魔力 +N1 灵魂', '没有变化']:
            with self.assertRaises(ValueError):
                compile_event_text('-N2 MAGIC.', target)
        with self.assertRaises(ValueError):
            compile_event_text('+N2 STAMINA and -N2 MIND.', '-N2 头脑换来 +N2 体力。')

    def test_restores_mission_reward_but_leaves_joke_rewards_alone(self):
        self.assertEqual(
            compile_event_text('+XX PRANK DOLLARZ and +1 NEW GRANDMA.', '+XX 恶作剧币，以及 +1 位新奶奶。'),
            '+XX PRANK DOLLARZ，以及 +1 位新奶奶。')
        with self.assertRaises(ValueError):
            compile_event_text('+XX PRANK DOLLARZ!', '你获得奖励！')
        with self.assertRaises(ValueError):
            compile_event_text('No reward.', '+XX 恶作剧币！')

    def test_built_validator_rejects_original_regression(self):
        with self.assertRaises(ValueError):
            validate_stat_text('gain +N2 HYPE!', '你获得 +N2 热度！')
        with self.assertRaises(ValueError):
            validate_stat_text('+XX PRANK DOLLARZ!', '+XX 恶作剧币！')

    def test_prose_variables_formatting_and_control_values_stay_unchanged(self):
        source = '%CURRENTPLAYERNAME% gets +N2 SOUL!'
        target = '%CURRENTPLAYERNAME%获得 [b]+N2 灵魂[/b]！[n]体力充沛。'
        built = compile_event_text(source, target)
        self.assertEqual(built, '%CURRENTPLAYERNAME%获得 [b]+N2 SOUL[/b]！[n]体力充沛。')
        self.assertEqual(compile_event_text('MIND', '头脑'), '头脑')

    def test_verb_sidecar_matches_compiled_event_text(self):
        import json
        import tempfile
        from runtime_verbs import compile_overrides
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            key = 'english_events_test:L1'
            rows = {key: {'source': '%HESHE%%VERB_IS_ARE% good. +N2 SOUL!',
                          'target': '%HESHE%%VERB_IS_ARE%真好。+N2 灵魂！'}}
            (path / 'runtime_verb_overrides_zh.json').write_text(
                json.dumps({key: {'%VERB_IS_ARE%': ''}}), encoding='utf-8')
            record = compile_overrides(path, rows)[0]
            self.assertIn('+N2 SOUL', record[1])
            self.assertIn('+N2 SOUL', record[2])
            self.assertNotIn('%VERB_IS_ARE%', record[2])
            self.assertIn('%HESHE%', record[2])


if __name__ == '__main__':
    unittest.main()
