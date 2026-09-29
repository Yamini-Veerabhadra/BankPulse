-- ============================================================
-- BankPulse: Data Quality Assessment
-- Purpose: Validate the raw banking marketing dataset
-- before performing business analysis.
-- ============================================================

-- 1. Verify total number of imported records
SELECT COUNT(*) AS total_records
FROM bank_marketing_raw;


-- 2. Check age and balance ranges
SELECT
    MIN(age) AS minimum_age,
    MAX(age) AS maximum_age,
    MIN(balance) AS minimum_balance,
    MAX(balance) AS maximum_balance,
    ROUND(AVG(balance), 2) AS average_balance
FROM bank_marketing_raw;

-- 3. Check for NULL values in important columns
SELECT
    COUNT(*) AS total_records,
    COUNT(*) - COUNT(age) AS null_age,
    COUNT(*) - COUNT(job) AS null_job,
    COUNT(*) - COUNT(marital) AS null_marital,
    COUNT(*) - COUNT(education) AS null_education,
    COUNT(*) - COUNT(balance) AS null_balance,
    COUNT(*) - COUNT(contact_type) AS null_contact_type,
    COUNT(*) - COUNT(subscribed) AS null_subscribed
FROM bank_marketing_raw;

-- 4. Check business-coded missing values ('unknown')
SELECT
    SUM(CASE WHEN job = 'unknown' THEN 1 ELSE 0 END) AS unknown_job,
    SUM(CASE WHEN education = 'unknown' THEN 1 ELSE 0 END) AS unknown_education,
    SUM(CASE WHEN contact_type = 'unknown' THEN 1 ELSE 0 END) AS unknown_contact_type,
    SUM(CASE WHEN previous_outcome = 'unknown' THEN 1 ELSE 0 END) AS unknown_previous_outcome
FROM bank_marketing_raw;

-- 5. Check for exact duplicate records
SELECT
    age,
    job,
    marital,
    education,
    credit_default,
    balance,
    housing_loan,
    personal_loan,
    contact_type,
    contact_day,
    contact_month,
    contact_duration,
    campaign_contacts,
    days_since_previous_contact,
    previous_contacts,
    previous_outcome,
    subscribed,
    COUNT(*) AS occurrence_count
FROM bank_marketing_raw
GROUP BY
    age,
    job,
    marital,
    education,
    credit_default,
    balance,
    housing_loan,
    personal_loan,
    contact_type,
    contact_day,
    contact_month,
    contact_duration,
    campaign_contacts,
    days_since_previous_contact,
    previous_contacts,
    previous_outcome,
    subscribed
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- 6. Validate categorical values

SELECT DISTINCT subscribed
FROM bank_marketing_raw
ORDER BY subscribed;

SELECT DISTINCT marital
FROM bank_marketing_raw
ORDER BY marital;

SELECT DISTINCT credit_default
FROM bank_marketing_raw
ORDER BY credit_default;

SELECT DISTINCT housing_loan
FROM bank_marketing_raw
ORDER BY housing_loan;

SELECT DISTINCT personal_loan
FROM bank_marketing_raw
ORDER BY personal_loan;