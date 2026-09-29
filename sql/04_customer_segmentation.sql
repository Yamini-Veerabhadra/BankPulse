-- ============================================================
-- BankPulse: Customer Segmentation Analysis
-- Purpose: Combine customer and campaign characteristics to
-- identify meaningful high- and low-response segments.
-- ============================================================

-- 1. Conversion by age group and balance segment using a CTE

WITH customer_segments AS (

    SELECT
        age,
        balance,
        subscribed,

        CASE
            WHEN age < 30 THEN 'Under 30'
            WHEN age BETWEEN 30 AND 39 THEN '30-39'
            WHEN age BETWEEN 40 AND 49 THEN '40-49'
            WHEN age BETWEEN 50 AND 59 THEN '50-59'
            ELSE '60+'
        END AS age_group,

        CASE
            WHEN balance < 0 THEN 'Negative Balance'
            WHEN balance = 0 THEN 'Zero Balance'
            WHEN balance <= 1000 THEN 'Low Balance'
            WHEN balance <= 5000 THEN 'Medium Balance'
            WHEN balance <= 10000 THEN 'High Balance'
            ELSE 'Very High Balance'
        END AS balance_segment

    FROM bank_marketing_raw
)

SELECT
    age_group,
    balance_segment,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,

    ROUND(
        100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS conversion_rate_pct

FROM customer_segments

GROUP BY
    age_group,
    balance_segment

ORDER BY
    conversion_rate_pct DESC;


-- 2. Age and balance segments with minimum sample-size threshold

WITH customer_segments AS (

    SELECT
        age,
        balance,
        subscribed,

        CASE
            WHEN age < 30 THEN 'Under 30'
            WHEN age BETWEEN 30 AND 39 THEN '30-39'
            WHEN age BETWEEN 40 AND 49 THEN '40-49'
            WHEN age BETWEEN 50 AND 59 THEN '50-59'
            ELSE '60+'
        END AS age_group,

        CASE
            WHEN balance < 0 THEN 'Negative Balance'
            WHEN balance = 0 THEN 'Zero Balance'
            WHEN balance <= 1000 THEN 'Low Balance'
            WHEN balance <= 5000 THEN 'Medium Balance'
            WHEN balance <= 10000 THEN 'High Balance'
            ELSE 'Very High Balance'
        END AS balance_segment

    FROM bank_marketing_raw
)

SELECT
    age_group,
    balance_segment,
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

FROM customer_segments

GROUP BY
    age_group,
    balance_segment

HAVING COUNT(*) >= 500

ORDER BY
    conversion_rate_pct DESC;

-- 3. Rank meaningful age and balance segments by conversion rate

WITH customer_segments AS (

    SELECT
        subscribed,

        CASE
            WHEN age < 30 THEN 'Under 30'
            WHEN age BETWEEN 30 AND 39 THEN '30-39'
            WHEN age BETWEEN 40 AND 49 THEN '40-49'
            WHEN age BETWEEN 50 AND 59 THEN '50-59'
            ELSE '60+'
        END AS age_group,

        CASE
            WHEN balance < 0 THEN 'Negative Balance'
            WHEN balance = 0 THEN 'Zero Balance'
            WHEN balance <= 1000 THEN 'Low Balance'
            WHEN balance <= 5000 THEN 'Medium Balance'
            WHEN balance <= 10000 THEN 'High Balance'
            ELSE 'Very High Balance'
        END AS balance_segment

    FROM bank_marketing_raw
),

segment_performance AS (

    SELECT
        age_group,
        balance_segment,
        COUNT(*) AS total_contacts,
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END) AS subscriptions,

        ROUND(
            100.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        ) AS conversion_rate_pct

    FROM customer_segments

    GROUP BY
        age_group,
        balance_segment

    HAVING COUNT(*) >= 500
)

SELECT
    RANK() OVER (
        ORDER BY conversion_rate_pct DESC
    ) AS segment_rank,

    age_group,
    balance_segment,
    total_contacts,
    subscriptions,
    conversion_rate_pct

FROM segment_performance

ORDER BY segment_rank;

-- 4. Conversion by combined housing and personal loan status

SELECT
    housing_loan,
    personal_loan,

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
    housing_loan,
    personal_loan

ORDER BY
    conversion_rate_pct DESC;

-- 5. Conversion by loan profile and previous campaign outcome

WITH customer_profiles AS (

    SELECT
        previous_outcome,
        subscribed,

        CASE
            WHEN housing_loan = 'no'
                 AND personal_loan = 'no'
                THEN 'No Loans'

            WHEN housing_loan = 'yes'
                 AND personal_loan = 'yes'
                THEN 'Both Loans'

            WHEN housing_loan = 'yes'
                 AND personal_loan = 'no'
                THEN 'Housing Loan Only'

            WHEN housing_loan = 'no'
                 AND personal_loan = 'yes'
                THEN 'Personal Loan Only'

            ELSE 'Other'
        END AS loan_profile

    FROM bank_marketing_raw
)

SELECT
    loan_profile,
    previous_outcome,
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

FROM customer_profiles

GROUP BY
    loan_profile,
    previous_outcome

ORDER BY
    conversion_rate_pct DESC;

-- 6. Conversion by previous campaign history segment

WITH campaign_history AS (

    SELECT
        subscribed,

        CASE
            WHEN previous_contacts = 0
                 AND days_since_previous_contact = -1
                THEN 'No Previous Campaign History'

            WHEN previous_outcome = 'success'
                THEN 'Previous Success'

            WHEN previous_outcome = 'failure'
                THEN 'Previous Failure'

            WHEN previous_outcome = 'other'
                THEN 'Previous Other Outcome'

            ELSE 'Unknown Previous History'
        END AS campaign_history_segment

    FROM bank_marketing_raw
)

SELECT
    campaign_history_segment,
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

FROM campaign_history

GROUP BY
    campaign_history_segment

ORDER BY
    conversion_rate_pct DESC;

-- 7. Multi-factor customer profile segmentation

WITH customer_profiles AS (

    SELECT
        subscribed,

        CASE
            WHEN age < 30 THEN 'Younger'
            WHEN age < 60 THEN 'Core Age'
            ELSE 'Older'
        END AS age_profile,

        CASE
            WHEN balance <= 0 THEN 'Non-Positive Balance'
            WHEN balance <= 1000 THEN 'Lower Balance'
            ELSE 'Higher Balance'
        END AS balance_profile,

        CASE
            WHEN housing_loan = 'no'
                 AND personal_loan = 'no'
                THEN 'No Loans'
            ELSE 'Has Loan'
        END AS loan_profile

    FROM bank_marketing_raw
),

profile_performance AS (

    SELECT
        age_profile,
        balance_profile,
        loan_profile,

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

    FROM customer_profiles

    GROUP BY
        age_profile,
        balance_profile,
        loan_profile

    HAVING COUNT(*) >= 500
)

SELECT
    RANK() OVER (
        ORDER BY conversion_rate_pct DESC
    ) AS profile_rank,

    age_profile,
    balance_profile,
    loan_profile,
    total_contacts,
    subscriptions,
    conversion_rate_pct

FROM profile_performance

ORDER BY profile_rank;

