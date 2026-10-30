-- ================================================================
-- BankPulse: Reconciliation and stakeholder-oriented business SQL
-- PostgreSQL; run after sql/01_database_setup.sql and CSV import.
-- Row grain = campaign record (not unique customer).
-- Subscribed-record denominator includes all rows with valid yes/no.
-- The questions below examine ASSOCIATIONS, not causal effects.
-- ================================================================

-- A. Validate response codes and baseline denominators.
SELECT
    COUNT(*) AS all_imported_records,
    COUNT(*) FILTER (WHERE subscribed IN ('yes', 'no')) AS eligible_records,
    COUNT(*) FILTER (WHERE subscribed = 'yes') AS subscribed_records,
    COUNT(*) FILTER (WHERE subscribed IS NULL
                     OR subscribed NOT IN ('yes', 'no')) AS invalid_response_records,
    ROUND(100.0 * COUNT(*) FILTER (WHERE subscribed = 'yes') /
           NULLIF(COUNT(*) FILTER (WHERE subscribed IN ('yes', 'no')), 0), 2)
           AS overall_conversion_pct
FROM bank_marketing_raw;

-- B. Prove that groups reconcile to the whole dataset without dropouts.
-- An invalid value falls into an explicit bucket instead of disappearing.
WITH overall AS (
    SELECT COUNT(*) AS records, COUNT(*) FILTER (WHERE subscribed = 'yes') AS yes_records
    FROM bank_marketing_raw
), labeled AS (
    SELECT 'campaign_contacts' AS dimension,
           CASE WHEN campaign_contacts = 1 THEN '1'
                WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3'
                WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5'
                WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10'
                WHEN campaign_contacts >= 11 THEN '11+'
                ELSE 'Invalid (under 1)' END AS segment,
           subscribed
    FROM bank_marketing_raw
    UNION ALL
    SELECT 'job', COALESCE(job, 'SQL NULL'), subscribed FROM bank_marketing_raw
    UNION ALL
    SELECT 'previous_outcome', COALESCE(previous_outcome, 'SQL NULL'), subscribed FROM bank_marketing_raw
    UNION ALL
    SELECT 'loan_profile',
           CASE WHEN housing_loan = 'no' AND personal_loan = 'no' THEN 'No housing or personal loan'
                WHEN housing_loan = 'yes' AND personal_loan = 'no' THEN 'Housing loan only'
                WHEN housing_loan = 'no' AND personal_loan = 'yes' THEN 'Personal loan only'
                WHEN housing_loan = 'yes' AND personal_loan = 'yes' THEN 'Both loan types'
                ELSE 'Unknown loan status' END,
           subscribed
    FROM bank_marketing_raw
), grouped AS (
    SELECT dimension, segment, COUNT(*) AS segment_records,
           COUNT(*) FILTER (WHERE subscribed = 'yes') AS segment_yes
    FROM labeled
    GROUP BY dimension, segment
), totals AS (
    SELECT dimension, SUM(segment_records) AS reconciled_records,
           SUM(segment_yes) AS reconciled_yes
    FROM grouped
    GROUP BY dimension
)
SELECT t.dimension, o.records AS source_records, t.reconciled_records,
       o.yes_records AS source_subscriptions, t.reconciled_yes,
       CASE WHEN o.records = t.reconciled_records
                 AND o.yes_records = t.reconciled_yes THEN 'PASS'
            ELSE 'FAIL' END AS reconciliation_result
FROM totals t CROSS JOIN overall o
ORDER BY t.dimension;

-- C. Unknown sensitivity: missing-code filtering changes the baseline.
-- Compare the unknown group to the known-only group; do not silently drop it.
WITH classified AS (
    SELECT 'contact_type' AS field,
           CASE WHEN contact_type = 'unknown' THEN 'unknown' ELSE 'known' END AS source_status,
           subscribed
    FROM bank_marketing_raw
    UNION ALL
    SELECT 'previous_outcome',
           CASE WHEN previous_outcome = 'unknown' THEN 'unknown' ELSE 'known' END,
           subscribed
    FROM bank_marketing_raw
)
SELECT field, source_status, COUNT(*) AS records,
       COUNT(*) FILTER (WHERE subscribed = 'yes') AS subscribed_records,
       ROUND(100.0 * COUNT(*) FILTER (WHERE subscribed = 'yes') /
             NULLIF(COUNT(*), 0), 2) AS conversion_pct
FROM classified
GROUP BY field, source_status
ORDER BY field, source_status;

-- Q1. Which job categories contribute volume vs. observed response rate?
-- Note: Grouping by job reflects campaign records, NOT unique customers.
WITH job_results AS (
    SELECT job, COUNT(*) AS records,
           COUNT(*) FILTER (WHERE subscribed = 'yes') AS subscriptions
    FROM bank_marketing_raw
    GROUP BY job
), total AS (
    SELECT SUM(subscriptions) AS all_subscriptions FROM job_results
)
SELECT j.job, j.records, j.subscriptions,
       ROUND(100.0 * j.subscriptions / NULLIF(j.records, 0), 2) AS conversion_pct,
       ROUND(100.0 * j.subscriptions / NULLIF(t.all_subscriptions, 0), 2)
           AS share_of_subscriptions_pct
FROM job_results j CROSS JOIN total t
ORDER BY j.subscriptions DESC;

-- Q2. How is previous campaign outcome associated with response?
SELECT previous_outcome, COUNT(*) AS records,
       COUNT(*) FILTER (WHERE subscribed = 'yes') AS subscriptions,
       ROUND(100.0 * COUNT(*) FILTER (WHERE subscribed = 'yes') /
             NULLIF(COUNT(*), 0), 2) AS conversion_pct
FROM bank_marketing_raw
GROUP BY previous_outcome
ORDER BY conversion_pct DESC;

-- Q3. How is the number of current campaign contacts associated with response?
-- NOT an estimate of the causal benefit/harm of additional contact.
WITH groups AS (
    SELECT CASE WHEN campaign_contacts = 1 THEN '1'
                WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3'
                WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5'
                WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10'
                WHEN campaign_contacts >= 11 THEN '11+'
                ELSE 'Invalid (under 1)' END AS contact_group,
           CASE WHEN campaign_contacts = 1 THEN 1
                WHEN campaign_contacts BETWEEN 2 AND 3 THEN 2
                WHEN campaign_contacts BETWEEN 4 AND 5 THEN 3
                WHEN campaign_contacts BETWEEN 6 AND 10 THEN 4
                WHEN campaign_contacts >= 11 THEN 5 ELSE 6 END AS sort_order,
           subscribed
    FROM bank_marketing_raw
)
SELECT contact_group, COUNT(*) AS records,
       COUNT(*) FILTER (WHERE subscribed = 'yes') AS subscriptions,
       ROUND(100.0 * COUNT(*) FILTER (WHERE subscribed = 'yes') /
             NULLIF(COUNT(*), 0), 2) AS conversion_pct
FROM groups
GROUP BY contact_group, sort_order
ORDER BY sort_order;
