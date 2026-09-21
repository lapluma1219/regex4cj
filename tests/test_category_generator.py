"""Regression tests for both Rust source layouts and fail-closed import."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from generate_categories import parse_table

class CategoryImportTests(unittest.TestCase):
    def test_inline_and_multiline_do_not_read_neighbor(self):
        text=r"""pub const CONTROL: &'static [(char, char)] =
          &[('\0', '\u{1f}'), ('\u{7f}', '\u{9f}')];
        pub const NEXT: &'static [(char, char)] = &[
          ('$', '$'),
        ];"""
        self.assertEqual(parse_table(text,'CONTROL'),[[0,31],[127,159]])
        self.assertEqual(parse_table(text,'NEXT'),[[36,36]])
    def test_surrogate_gap_is_split(self):
        self.assertEqual(parse_table(r"pub const X: T = &[('\u{d7ff}', '\u{e000}')];",'X'),
                         [[0xd7ff,0xd7ff],[0xe000,0xe000]])
    def test_unparsed_source_is_rejected(self):
        for body in ["garbage, ('a', 'b')", "('a', 'b'), trailing", ""]:
            with self.assertRaises(ValueError): parse_table('pub const X: T = &['+body+'];','X')
    def test_missing_table_does_not_use_next(self):
        with self.assertRaises(ValueError):parse_table("pub const NEXT: T = &[('a', 'b')];",'X')

if __name__=='__main__':unittest.main()
