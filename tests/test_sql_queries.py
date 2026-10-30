"""SQL smoke tests using stdlib SQLite, not a PostgreSQL execution claim.

Run all bundled read-only statements against a full in-memory import of bank-full.csv.
SQLite 3.46+ accepts the SQL constructs currently used (CTEs, windows, FILTER).
This catches broken column names, statement syntax, and many runtime logic mistakes.
"""
import csv
import sqlite3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_COLUMNS = [
    'age', 'job', 'marital', 'education', 'default', 'balance', 'housing',
    'loan', 'contact', 'day', 'month', 'duration', 'campaign', 'pdays',
    'previous', 'poutcome', 'y',
]
DB_COLUMNS = [
    'age', 'job', 'marital', 'education', 'credit_default', 'balance',
    'housing_loan', 'personal_loan', 'contact_type', 'contact_day',
    'contact_month', 'contact_duration', 'campaign_contacts',
    'days_since_previous_contact', 'previous_contacts', 'previous_outcome',
    'subscribed',
]
EXPECTED_QUERIES = {
    '02_data_quality.sql': 10,
    '03_exploratory_analysis.sql': 11,
    '04_customer_segmentation.sql': 7,
    '05_campaign_analysis.sql': 13,
    '06_advanced_analysis.sql': 10,
    '07_business_validation.sql': 6,
}


def split_sql(script):
    """Return statements with original comments; don't split on inline ';'."""
    buffer = []
    for line in script.splitlines(keepends=True):
        buffer.append(line)
        candidate = ''.join(buffer)
        if sqlite3.complete_statement(candidate):
            if any(l.strip() and not l.lstrip().startswith('--') for l in buffer):
                yield candidate
            buffer.clear()
    if ''.join(buffer).strip():
        raise AssertionError('Unterminated SQL statement')


class SQLQueryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.conn = sqlite3.connect(':memory:')
        cols = ['customer_id INTEGER PRIMARY KEY'] + [
            c + (' INTEGER' if c in {
                'age', 'balance', 'contact_day', 'contact_duration',
                'campaign_contacts', 'days_since_previous_contact', 'previous_contacts',
            } else ' TEXT') for c in DB_COLUMNS
        ]
        cls.conn.execute('CREATE TABLE bank_marketing_raw (' + ','.join(cols) + ')')
        with (ROOT / 'data/raw/bank-full.csv').open(encoding='utf-8-sig', newline='') as handle:
            reader = csv.reader(handle, delimiter=';', quotechar='"')
            header = next(reader)
            if header != SOURCE_COLUMNS:
                raise AssertionError(f'Source headers changed: {header}')
            cls.conn.executemany(
                'INSERT INTO bank_marketing_raw (' + ','.join(DB_COLUMNS) + ')'
                ' VALUES (' + ','.join('?' for _ in DB_COLUMNS) + ')', reader,
            )

    @classmethod
    def tearDownClass(cls):
        cls.conn.close()

    def test_imported_totals(self):
        count, yes = self.conn.execute('''
            SELECT COUNT(*), COUNT(*) FILTER (WHERE subscribed='yes')
            FROM bank_marketing_raw''').fetchone()
        self.assertEqual((count, yes), (45211, 5289))

    def test_all_57_analysis_queries_execute(self):
        for filename, expected_count in EXPECTED_QUERIES.items():
            script = (ROOT / 'sql' / filename).read_text(encoding='utf-8-sig')
            queries = list(split_sql(script))
            with self.subTest(filename=filename):
                self.assertEqual(len(queries), expected_count)
                for index, query in enumerate(queries, 1):
                    with self.subTest(filename=filename, query=index):
                        result = self.conn.execute(query)
                        self.assertTrue(result.description)
                        result.fetchall()  # Execute to completion, not just parse.

    def test_reconciliation_query_returns_pass(self):
        queries = list(split_sql((ROOT/'sql/07_business_validation.sql').read_text()))
        baseline = self.conn.execute(queries[0]).fetchone()
        self.assertEqual(baseline, (45211, 45211, 5289, 0, 11.70))
        recs = self.conn.execute(queries[1]).fetchall()
        self.assertEqual(len(recs), 4)
        self.assertEqual({row[0] for row in recs},
                         {'campaign_contacts', 'job', 'previous_outcome', 'loan_profile'})
        self.assertTrue(all(row[-1] == 'PASS' for row in recs))

    def test_postgres_import_maps_all_source_fields(self):
        psql = (ROOT/'scripts/setup_and_import.psql').read_text()
        self.assertIn('\\set ON_ERROR_STOP on', psql)
        self.assertIn('BEGIN;', psql)
        self.assertIn('COMMIT;', psql)
        self.assertIn('\\i sql/01_database_setup.sql', psql)
        import re
        match = re.search(r'\\copy\s+bank_marketing_raw\s*\(([^)]+)\)\s+FROM', psql, re.I)
        self.assertIsNotNone(match)
        self.assertEqual([v.strip() for v in match.group(1).split(',')], DB_COLUMNS)
        self.assertIn("DELIMITER ';'", psql)
        self.assertIn('HEADER true', psql)
        self.assertIn('customer_id SERIAL PRIMARY KEY',
                      (ROOT/'sql/01_database_setup.sql').read_text())


if __name__ == '__main__':
    unittest.main()
