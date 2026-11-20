"""Regression checks for reported school names and hitchhiker tooltip content."""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from translation_common import load_rows


class SchoolAndTooltipTexts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = load_rows(ROOT / 'translation')

    def test_spooky_academy_and_existing_overrides_use_user_name(self):
        rows = [r for r in self.rows.values() if 'Spooky Academy' in r['source']]
        self.assertEqual(len(rows), 23)
        overrides = {}
        for name in ('seed_zh.json', 'quality_overrides_zh.json'):
            overrides.update(json.loads((ROOT / 'translation' / name).read_text(encoding='utf-8-sig')))
        for row in rows:
            with self.subTest(row=row['row_id']):
                self.assertIn('魔物学园', row['target'])
                self.assertNotIn('惊悚学院', row['target'])
                if row['row_id'] in overrides:
                    self.assertEqual(overrides[row['row_id']], row['target'])
        glossary = json.loads((ROOT / 'translation/glossary.json').read_text(encoding='utf-8'))
        locations = json.loads((ROOT / 'translation/location_names_zh.json').read_text(encoding='utf-8'))
        self.assertEqual(glossary['Spooky Academy'], '魔物学园')
        self.assertEqual(locations['RML_SPOOKY_ACADEMY'], '魔物学园')

    def test_liam_conversation_and_rebranding_context(self):
        for line in (6168, 6169):
            self.assertIn('魔物学园', self.rows[f'english_events_pitstop:L{line}']['target'])
        # High and Academy share the approved Chinese school name; retain the joke.
        renamed = self.rows['english_events_pitstop:L3438']['target']
        self.assertIn('高中', renamed)
        self.assertIn('魔物学园', renamed)

    def test_hitchhiker_tooltip_texts_are_present(self):
        rows = [r for r in self.rows.values() if r['row_id'].startswith('english_metatexts:TOO_PSN_')]
        self.assertGreater(len(rows), 20)
        for row in rows:
            with self.subTest(row=row['row_id']):
                self.assertTrue(row['target'].strip())
        liam = self.rows['english_metatexts:TOO_PSN_LIAM']['target']
        self.assertIn('头脑', liam)
        self.assertIn('热度', liam)


if __name__ == '__main__':
    unittest.main()
