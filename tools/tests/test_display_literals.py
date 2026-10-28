import sys
import unittest
import csv
import io
import json
import tempfile
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from translation_common import extract_tokens, row_display_literals
import validate_translation


class DisplayLiteralTests(unittest.TestCase):
    def setUp(self):
        self.row = {"row_id": "approved", "source": "<READY %NAME%> [n][b]", "target": "<就绪 %NAME%> [n][b]"}
        self.overrides = {"approved": [{"source": "<READY %NAME%>", "target": "<就绪 %NAME%>"}]}

    def test_exact_scoped_pair_keeps_nested_variables_and_real_tags(self):
        literals = row_display_literals(self.row, self.overrides)
        self.assertEqual(extract_tokens(self.row["source"], literals), {"%NAME%": 1, "[n]": 1, "[b]": 1})
        self.assertEqual(extract_tokens(self.row["source"], literals), extract_tokens(self.row["target"], literals))

    def test_same_words_in_another_row_stay_protected(self):
        other = dict(self.row, row_id="not-approved")
        literals = row_display_literals(other, self.overrides)
        self.assertNotEqual(extract_tokens(other["source"], literals), extract_tokens(other["target"], literals))

    def test_changed_or_missing_approved_text_fails_closed(self):
        for target in ["<就绪 %NAME%> <就绪 %NAME%>", "就绪", "<就绪 %OTHER%>"]:
            with self.subTest(target=target), self.assertRaises(ValueError):
                row_display_literals(dict(self.row, target=target), self.overrides)

    def test_even_a_registered_literal_cannot_hide_a_missing_variable(self):
        row = dict(self.row, target="<就绪> [n][b]")
        overrides = {"approved": [{"source": "<READY %NAME%>", "target": "<就绪>"}]}
        literals = row_display_literals(row, overrides)
        self.assertNotEqual(extract_tokens(row["source"], literals), extract_tokens(row["target"], literals))

    def test_unknown_new_tags_remain_protected(self):
        literals = row_display_literals(self.row, self.overrides)
        self.assertNotEqual(extract_tokens(self.row["source"], literals), extract_tokens(self.row["target"] + "[NEW]", literals))

    def test_known_control_and_formatting_tags_cannot_be_exempted(self):
        for token in ["[n]", "[0]", "[b]", "[/B]", "[FFEEAA]", "[url=https://example.com]", "<b>", "<color=red>"]:
            with self.subTest(token=token), self.assertRaises(ValueError):
                row_display_literals({"row_id": "r", "source": token, "target": token}, {"r": [{"source": token, "target": token}]})

    def test_original_literal_cannot_be_duplicated_beside_its_translation(self):
        with self.assertRaises(ValueError):
            row_display_literals(dict(self.row, target=self.row["source"] + self.row["target"]), self.overrides)

    def test_nested_display_square_text_needs_its_own_approval(self):
        row = {"row_id": "approved", "source": "<OK [DOG]>", "target": "<好 [狗]>"}
        overrides = {"approved": [{"source": row["source"], "target": row["target"]}]}
        literals = row_display_literals(row, overrides)
        self.assertNotEqual(extract_tokens(row["source"], literals), extract_tokens(row["target"], literals))
        overrides["approved"].append({"source": "[DOG]", "target": "[狗]"})
        literals = row_display_literals(row, overrides)
        self.assertEqual(extract_tokens(row["source"], literals), extract_tokens(row["target"], literals))

    def run_csv_validation(self, target):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            with (root / "english_test.csv").open("w", encoding="utf-8-sig", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=["row_id", "source", "target"])
                writer.writeheader()
                writer.writerow(dict(self.row, target=target))
            (root / "display_literal_overrides.json").write_text(json.dumps(self.overrides), encoding="utf-8")
            output = io.StringIO()
            with patch.object(sys, "argv", ["validate_translation", "--translation", str(root)]), redirect_stdout(output):
                result = validate_translation.main()
            return result, output.getvalue()

    def test_csv_validator_accepts_the_exact_localized_pair(self):
        result, output = self.run_csv_validation(self.row["target"])
        self.assertEqual(result, 0, output)

    def test_csv_validator_rejects_a_completely_deleted_target(self):
        result, output = self.run_csv_validation("")
        self.assertEqual(result, 1, output)
        self.assertIn("approved display literal target is missing", output)


if __name__ == "__main__":
    unittest.main()
