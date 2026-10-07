"""Check that catalog omissions fail closed rather than inflating coverage."""
import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('feature_catalog', Path(__file__).resolve().parents[2]/'scripts/feature_catalog.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.catalog, self.cases = module.load()

    def test_registered(self):
        module.validate(self.catalog, self.cases)

    def test_missing_suite_rejected(self):
        self.catalog['groups'][0]['features'].pop()
        with self.assertRaises(AssertionError):
            module.validate(self.catalog, self.cases)

    def test_duplicate_case_rejected(self):
        with self.assertRaises(AssertionError):
            module.validate(self.catalog, self.cases + [copy.deepcopy(self.cases[0])])

    def test_unknown_group_rejected(self):
        self.cases[0]['group'] = 'nonexistent'
        with self.assertRaises(AssertionError):
            module.validate(self.catalog, self.cases)

    def test_unknown_api_rejected(self):
        self.cases[0]['api_refs'] = ['Regex.notAnApi']
        with self.assertRaises(AssertionError):
            module.validate(self.catalog, self.cases)

    def test_case_evidence_is_not_full_coverage(self):
        _, api = module.documents(self.catalog, self.cases)
        self.assertIn('部分特性案例：', api)
        self.assertIn('待逐项审计', api)

    def test_static_report_does_not_claim_pass(self):
        doc, _ = module.documents(self.catalog, self.cases)
        self.assertNotIn('| passed |', doc)
        self.assertIn('未运行（静态目录）', doc)


if __name__ == '__main__':
    unittest.main()
