import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from runtime_verbs import compile_overrides, build_overrides, validate_overrides


class RuntimeVerbTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.key = 'english_events_pitstop:L1'
        self.rows = {self.key: {'source': "%HESHE%%VERB_'S_'RE% nice", 'target': "%HESHE%%VERB_'S_'RE%好人"}}
        self.write({self.key: {"%VERB_'S_'RE%": '是'}})

    def write(self, value):
        (self.path/'runtime_verb_overrides_zh.json').write_text(json.dumps(value), encoding='utf-8')

    def test_copula_is_contextual_and_pronoun_survives(self):
        self.assertEqual(compile_overrides(self.path, self.rows)[0][2], '%HESHE%是好人')
        self.rows[self.key]['target'] = "%HESHE%%VERB_'S_'RE%很好"
        self.write({self.key: {"%VERB_'S_'RE%": ''}})
        self.assertEqual(compile_overrides(self.path, self.rows)[0][2], '%HESHE%很好')

    def test_missing_or_unknown_rows_fail(self):
        self.write({})
        with self.assertRaises(ValueError): compile_overrides(self.path, self.rows)
        self.write({'english_events_pitstop:L2': {"%VERB_'S_'RE%": '是'}})
        with self.assertRaises(ValueError): compile_overrides(self.path, self.rows)

    def test_wrong_token_or_injected_control_fails(self):
        for replacement in ({'%HESHE%': '他'}, {"%VERB_'S_'RE%": '\t'}, {"%VERB_'S_'RE%": '%HESHE%'}, {"%VERB_'S_'RE%": 'is'}):
            self.write({self.key: replacement})
            with self.assertRaises(ValueError): compile_overrides(self.path, self.rows)

    def test_duplicate_json_key_fails(self):
        (self.path/'runtime_verb_overrides_zh.json').write_text('{"x": {}, "x": {}}', encoding='utf-8')
        with self.assertRaises(ValueError): compile_overrides(self.path, self.rows)

    def test_stale_sidecar_and_stale_event_fail(self):
        build_overrides(self.path, self.rows, self.path)
        event=self.path/'schinese_events_pitstop.txt'
        event.write_text('speaker\tmood\tcondition\t'+self.rows[self.key]['target']+'\tsound\n', encoding='utf-8')
        self.assertEqual(validate_overrides(self.path, self.rows, self.path), [])
        event.write_text('speaker\tmood\tcondition\tSTALE\tsound\n', encoding='utf-8')
        self.assertTrue(validate_overrides(self.path, self.rows, self.path))
        (self.path/'schinese_verb_overrides.tsv').write_text('', encoding='utf-8')
        self.assertTrue(validate_overrides(self.path, self.rows, self.path))


if __name__ == '__main__':
    unittest.main()
