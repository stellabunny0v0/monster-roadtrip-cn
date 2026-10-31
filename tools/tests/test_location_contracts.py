import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from location_contracts import validate_location_names


class LocationContractsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.names = {'RML_DINER_DINEST': '至臻餐厅', 'RML_DINER_DINEST_EOTR': '至臻餐厅',
                      'RML_SIMON_SOUPS': '西蒙汤馆', 'DTT_MUSIC_FESTIVAL': '维拉诺顿音乐节'}
        self.rows = {'english_metatexts:' + key: {'target': value} for key, value in self.names.items()}
        (self.path / 'location_names_zh.json').write_text(json.dumps(self.names), encoding='utf-8')

    def test_complete_ui_names_and_eotr_variants_pass(self):
        self.assertEqual(validate_location_names(self.path, self.rows, self.names), [])

    def test_missing_key_or_english_target_fails(self):
        del self.rows['english_metatexts:RML_DINER_DINEST_EOTR']
        self.assertTrue(validate_location_names(self.path, self.rows))
        self.rows['english_metatexts:RML_DINER_DINEST_EOTR'] = {'target': 'The Dinest'}
        self.assertTrue(validate_location_names(self.path, self.rows))

    def test_stale_runtime_name_fails(self):
        built = dict(self.names, RML_DINER_DINEST='The Dinest')
        self.assertTrue(validate_location_names(self.path, self.rows, built))

    def test_untranslated_approved_name_and_unknown_ui_key_fail(self):
        (self.path / 'location_names_zh.json').write_text(json.dumps({'RML_DINER_DINEST': 'The Dinest'}), encoding='utf-8')
        self.assertTrue(validate_location_names(self.path, self.rows))
        self.rows['english_metatexts:RML_NEW_PLACE'] = {'target': '新地点'}
        self.assertTrue(validate_location_names(self.path, self.rows))


if __name__ == '__main__':
    unittest.main()
