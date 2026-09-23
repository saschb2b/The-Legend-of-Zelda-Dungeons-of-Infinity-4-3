import importlib.util
import unittest
from pathlib import Path
from xml.etree import ElementTree as ET

RUNNER = Path(__file__).resolve().parents[1] / 'device/run_device.py'
spec = importlib.util.spec_from_file_location('run_device', RUNNER)
run_device = importlib.util.module_from_spec(spec)
spec.loader.exec_module(run_device)

REPORT = {'complete': True, 'suites': [
    {'name': 'Pause menu', 'tests': [
        {'name': 'opens on Resume', 'passed': True, 'checks': 3, 'failures': []},
        {'name': 'every close input resumes', 'passed': False, 'checks': 5, 'failures': ['Back resumes from the pause list']},
    ]},
    {'name': 'HUD scaling', 'tests': [{'name': 'fits every screen', 'passed': True, 'checks': 80, 'failures': []}]},
]}


class DeviceReportTests(unittest.TestCase):
    def test_summary_counts_suites_tests_and_checks(self):
        lines, passed = run_device.summarize(REPORT)
        self.assertFalse(passed)
        self.assertIn('2 suites, 3 tests, 88 checks; 1 tests failed', lines)
        self.assertTrue(lines[0].startswith('FAIL Pause menu'))
        self.assertTrue(lines[1].startswith('ok   HUD scaling'))

    def test_summary_names_each_failed_check(self):
        lines, _ = run_device.summarize(REPORT)
        failure = lines.index('FAIL Pause menu > every close input resumes')
        self.assertEqual(lines[failure + 1], '     - Back resumes from the pause list')

    def test_passing_report(self):
        report = {'suites': [REPORT['suites'][1]]}
        lines, passed = run_device.summarize(report)
        self.assertTrue(passed)
        self.assertEqual(lines[-1], '1 suites, 1 tests, 80 checks; 0 tests failed')

    def test_junit_lists_test_cases_with_failures(self):
        root = ET.fromstring(run_device.junit(REPORT))
        self.assertEqual((root.get('tests'), root.get('failures')), ('3', '1'))
        cases = root.findall('testsuite/testcase')
        self.assertEqual([case.get('name') for case in cases], ['opens on Resume', 'every close input resumes', 'fits every screen'])
        failure = cases[1].find('failure')
        self.assertEqual(failure.get('message'), 'Back resumes from the pause list')
        self.assertIsNone(cases[0].find('failure'))


if __name__ == '__main__':
    unittest.main()
