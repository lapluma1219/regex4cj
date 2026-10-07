"""Coverage parser must not inflate totals or turn missing data into success."""
import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'scripts'))
from measure_test_coverage import summarize, prepare_workspace


class CoverageReportTests(unittest.TestCase):
    def test_union_profiles_without_double_counting_and_preserve_unmeasured(self):
        with tempfile.TemporaryDirectory() as directory:
            paths = []
            for index, count in enumerate(['#####', '2']):
                path = Path(directory)/f'{index}.gcov'
                path.write_text(f'        -:    0:Source:/tmp/project/port/src/example.cj\n'
                                f'function sample called {index} returned 100% blocks executed 100%\n'
                                f'    {count}:   10:public func sample() {{\n'
                                f'    #####:   11:    rejected()\n'
                                f'        -:   12:}}\n')
                paths.append(path)
            items = [dict(file='port/src/example.cj', line=line, kind='method', name=f'f{line}') for line in (10, 99)]
            result = summarize(paths, items)
            self.assertEqual((result['hit_lines'], result['executable_lines']), (1, 2))
            self.assertEqual((result['public_hit'],result['public_unmeasured']), (1,1))
            self.assertEqual(result['files'][0]['missed_lines'], [11])

    def test_absent_profiles_are_failure(self):
        with self.assertRaises(RuntimeError):
            summarize([], [])

    def test_non_library_source_is_excluded(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'other.gcov'
            path.write_text('        -:    0:Source:/tmp/cli/src/main.cj\n        1:    2:main() {}\n')
            with self.assertRaises(RuntimeError):
                summarize([path], [])


class CoverageWorkspaceTests(unittest.TestCase):
    def test_copy_keeps_version_and_inputs_but_discards_old_profiles(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, destination = root/'source', root/'copy'
            source.mkdir(); destination.mkdir()
            for folder in ['port', 'cli', 'oracle', 'tests', 'scripts', 'examples', 'data', 'docs']:
                (source/folder).mkdir()
                (source/folder/'input.txt').write_text('required')
                (source/folder/'old.gcda').write_text('stale')
                (source/folder/'target').mkdir()
                (source/folder/'target'/'cache').write_text('stale')
            (source/'VERSION').write_text('0.3.0\n')
            prepare_workspace(source, destination)
            self.assertEqual((destination/'VERSION').read_text(), '0.3.0\n')
            for folder in ['port', 'cli', 'oracle', 'tests', 'scripts', 'examples', 'data', 'docs']:
                self.assertEqual((destination/folder/'input.txt').read_text(), 'required')
                self.assertFalse((destination/folder/'old.gcda').exists())
                self.assertFalse((destination/folder/'target').exists())
