-- ============================================================
-- BankPulse: Exploratory Data Analysis
-- Purpose: Understand customer composition, financial profiles,
-- campaign behavior, and term-deposit subscription patterns.
-- ============================================================
-- 1. Overall term-deposit subscription performance

SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscribed_customers,
    SUM(CASE WHEN subscribed = 'no' THEN 1 ELSE 0 END) AS non_subscribed_customers,
    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct
FROM bank_marketing_raw;

-- 2. Term-deposit conversion rate by job

SELECT
    job,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct
FROM bank_marketing_raw
GROUP BY job
ORDER BY conversion_rate_pct DESC;

-- 3. Term-deposit conversion by account balance segment

SELECT
    CASE
        WHEN balance < 0 THEN 'Negative Balance'
        WHEN balance = 0 THEN 'Zero Balance'
        WHEN balance <= 1000 THEN 'Low Balance (1-1,000)'
        WHEN balance <= 5000 THEN 'Medium Balance (1,001-5,000)'
        WHEN balance <= 10000 THEN 'High Balance (5,001-10,000)'
        ELSE 'Very High Balance (10,000+)'
    END AS balance_segment,

    COUNT(*) AS total_contacts,

    SUM(
        CASE
            WHEN subscribed = 'yes' THEN 1
            ELSE 0
        END
    ) AS subscriptions,

    ROUND(
        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct

FROM bank_marketing_raw

GROUP BY
    CASE
        WHEN balance < 0 THEN 'Negative Balance'
        WHEN balance = 0 THEN 'Zero Balance'
        WHEN balance <= 1000 THEN 'Low Balance (1-1,000)'
        WHEN balance <= 5000 THEN 'Medium Balance (1,001-5,000)'
        WHEN balance <= 10000 THEN 'High Balance (5,001-10,000)'
        ELSE 'Very High Balance (10,000+)'
    END

ORDER BY conversion_rate_pct DESC;

-- 4. Term-deposit conversion by housing loan status

SELECT
    housing_loan,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct
FROM bank_marketing_raw
GROUP BY housing_loan
ORDER BY conversion_rate_pct DESC;

-- 5. Term-deposit conversion by personal loan status

SELECT
    personal_loan,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct
FROM bank_marketing_raw
GROUP BY personal_loan
ORDER BY conversion_rate_pct DESC;

-- 6. Conversion rate by number of campaign contacts

SELECT
    campaign_contacts,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct
FROM bank_marketing_raw
GROUP BY campaign_contacts
ORDER BY campaign_contacts;

-- 7. Conversion rate by campaign contact frequency segment

SELECT
    CASE
        WHEN campaign_contacts = 1 THEN '1 Contact'
        WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3 Contacts'
        WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5 Contacts'
        WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10 Contacts'
        ELSE '11+ Contacts'
    END AS contact_frequency,

    COUNT(*) AS total_contacts,

    SUM(
        CASE
            WHEN subscribed = 'yes' THEN 1
            ELSE 0
        END
    ) AS subscriptions,

    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct

FROM bank_marketing_raw

GROUP BY
    CASE
        WHEN campaign_contacts = 1 THEN '1 Contact'
        WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3 Contacts'
        WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5 Contacts'
        WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10 Contacts'
        ELSE '11+ Contacts'
    END

ORDER BY
    MIN(campaign_contacts);

-- 8. Investigate previous campaign history

SELECT
    previous_contacts,
    days_since_previous_contact,
    previous_outcome,
    COUNT(*) AS total_records
FROM bank_marketing_raw
GROUP BY
    previous_contacts,
    days_since_previous_contact,
    previous_outcome
ORDER BY
    total_records DESC
LIMIT 20;

-- 9. Current conversion rate by previous campaign outcome

SELECT
    previous_outcome,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct
FROM bank_marketing_raw
GROUP BY previous_outcome
ORDER BY conversion_rate_pct DESC;

-- 10. Term-deposit conversion by contact type

SELECT
    contact_type,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,
    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct
FROM bank_marketing_raw
GROUP BY contact_type
ORDER BY conversion_rate_pct DESC;

-- 11. Term-deposit conversion by age group

SELECT
    CASE
        WHEN age < 30 THEN 'Under 30'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END AS age_group,

    COUNT(*) AS total_contacts,

    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,

    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct

FROM bank_marketing_raw

GROUP BY
    CASE
        WHEN age < 30 THEN 'Under 30'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END

ORDER BY MIN(age);

