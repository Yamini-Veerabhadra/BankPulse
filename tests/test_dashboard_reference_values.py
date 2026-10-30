"""Independently validate numeric labels captured in supplied dashboard screenshots.

IMPORTANT: This reads the original CSV, not the Power BI engine. It confirms that
screenshot reference numbers are consistent with source data; it cannot verify DAX,
rendering, or interactions in a fresh Power BI Desktop session.
"""
import csv
import unittest
from collections import defaultdict
from pathlib import Path
from statistics import mean

DATA = Path(__file__).resolve().parents[1] / 'data/raw/bank-full.csv'


class DashboardReferenceValuesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with DATA.open(encoding='utf-8-sig', newline='') as fh:
            cls.rows = list(csv.DictReader(fh, delimiter=';'))

    def grouped(self, key):
        groups = defaultdict(lambda: [0, 0])
        for row in self.rows:
            group = key(row)
            groups[group][0] += 1
            groups[group][1] += (row['y'] == 'yes')
        return {k: (n, yes, round(100 * yes / n, 2)) for k, (n, yes) in groups.items()}

    def test_month_conversion_labels_on_campaign_overview(self):
        labels = {'jan': 10.12, 'feb': 16.65, 'mar': 51.99, 'apr': 19.68,
                  'may': 6.72, 'jun': 10.22, 'jul': 9.09, 'aug': 11.01,
                  'sep': 46.46, 'oct': 43.77, 'nov': 10.15, 'dec': 46.73}
        actual = self.grouped(lambda r: r['month'])
        self.assertEqual(set(labels), set(actual))
        for month, percent in labels.items():
            with self.subTest(month=month):
                self.assertEqual(actual[month][2], percent)

    def test_contact_type_chart(self):
        expected = {'cellular': 14.92, 'telephone': 13.42, 'unknown': 4.07}
        actual = self.grouped(lambda r: r['contact'])
        for key, pct in expected.items():
            with self.subTest(type=key):
                self.assertEqual(actual[key][2], pct)

    def test_age_group_chart(self):
        def band(row):
            age = int(row['age'])
            if age < 30: return 'Under 30'
            if age < 40: return '30-39'
            if age < 50: return '40-49'
            if age < 60: return '50-59'
            return '60+'
        expected = {'Under 30': 17.60, '30-39': 10.58, '40-49': 9.12,
                    '50-59': 9.33, '60+': 33.63}
        self.assertEqual({k: v[2] for k, v in self.grouped(band).items()}, expected)

    def test_call_duration_means_on_customer_insights(self):
        for outcome, expected in [('yes', 537.29), ('no', 221.18)]:
            lengths = [int(r['duration']) for r in self.rows if r['y'] == outcome]
            self.assertEqual(round(mean(lengths), 2), expected)

    def test_job_conversion_and_subscription_chart(self):
        actual = self.grouped(lambda r: r['job'])
        for job, count, pct in [('management', 1301, 13.76), ('technician', 840, 11.06),
                                ('blue-collar', 708, 7.27), ('student', 269, 28.68),
                                ('retired', 516, 22.79)]:
            with self.subTest(job=job):
                self.assertEqual(actual[job][1:], (count, pct))


if __name__ == '__main__':
    unittest.main()
