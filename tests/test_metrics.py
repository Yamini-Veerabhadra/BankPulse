"""Run from project root: python -m unittest discover -s tests -v"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from validate_metrics import analyze, contact_bucket, load_rows, loan_bucket


class BankPulseValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.metrics = analyze(load_rows())

    def test_original_record_baseline(self):
        m = self.metrics
        self.assertEqual(m['total_records'], 45211)
        self.assertEqual(m['total_subscriptions'], 5289)
        self.assertAlmostEqual(m['overall_conversion_pct'], 11.70, delta=.005)
        self.assertEqual(m['invalid_target_values'], 0)
        self.assertEqual(m['exact_duplicate_source_rows'], 0)

    def test_all_partitions_reconcile(self):
        for dimension, result in self.metrics['reconciliations'].items():
            with self.subTest(dimension=dimension):
                self.assertTrue(result['records_match'])
                self.assertTrue(result['subscriptions_match'])

    def test_contact_frequency_counts(self):
        expected = {'1': (17544, 2561), '2-3': (18026, 2019),
                    '4-5': (5286, 456), '6-10': (3159, 206), '11+': (1196, 47)}
        groups = self.metrics['groups']['contact_frequency']
        for key, (records, subs) in expected.items():
            with self.subTest(group=key):
                self.assertEqual((groups[key]['records'], groups[key]['subscriptions']), (records, subs))

    def test_job_and_previous_outcome(self):
        groups = self.metrics['groups']
        self.assertEqual(groups['job_category']['management']['subscriptions'], 1301)
        self.assertEqual(groups['job_category']['student']['subscriptions'], 269)
        self.assertEqual(groups['previous_outcome']['success']['subscriptions'], 978)
        self.assertEqual(groups['previous_outcome']['unknown']['records'], 36959)

    def test_unknown_not_dropped(self):
        info = self.metrics['unknown_sensitivity']['contact']
        self.assertEqual(info['unknown_records'], 13020)
        self.assertEqual(info['known_records'], 32191)

    def test_contact_bucket_boundaries(self):
        self.assertEqual([contact_bucket(x) for x in (1, 2, 3, 4, 5, 6, 10, 11)],
                         ['1', '2-3', '2-3', '4-5', '4-5', '6-10', '6-10', '11+'])
        self.assertEqual(contact_bucket(0), 'Invalid (under 1)')

    def test_loan_bucket(self):
        self.assertEqual(loan_bucket({'housing': 'no', 'loan': 'no'}), 'No housing or personal loan')
        self.assertEqual(loan_bucket({'housing': 'yes', 'loan': 'yes'}), 'Both loan types')


if __name__ == '__main__':
    unittest.main()
