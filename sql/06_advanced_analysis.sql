-- ============================================================
-- BankPulse: Advanced SQL Analysis
-- Purpose: Apply advanced SQL techniques including window
-- functions, ranking, benchmark comparisons, cumulative
-- analysis, and multi-dimensional campaign analysis.
-- ============================================================


-- ============================================================
-- 1. Rank job categories by conversion performance
-- ============================================================

WITH job_performance AS (

    SELECT
        job,
        COUNT(*) AS total_records,

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

    GROUP BY job
)

SELECT
    DENSE_RANK() OVER (
        ORDER BY conversion_rate_pct DESC
    ) AS conversion_rank,

    job,
    total_records,
    subscriptions,
    conversion_rate_pct

FROM job_performance

ORDER BY conversion_rank;



-- ============================================================
-- 2. Rank balance segments within each age group
-- Demonstrates PARTITION BY
-- ============================================================

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

        COUNT(*) AS total_records,

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

    HAVING COUNT(*) >= 100
)

SELECT
    age_group,
    balance_segment,
    total_records,
    subscriptions,
    conversion_rate_pct,

    DENSE_RANK() OVER (
        PARTITION BY age_group
        ORDER BY conversion_rate_pct DESC
    ) AS rank_within_age_group

FROM segment_performance

ORDER BY
    age_group,
    rank_within_age_group;



-- ============================================================
-- 3. Compare each job's conversion rate with overall average
-- ============================================================

WITH overall_performance AS (

    SELECT
        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS overall_conversion_rate

    FROM bank_marketing_raw
),

job_performance AS (

    SELECT
        job,

        COUNT(*) AS total_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS subscriptions,

        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS job_conversion_rate

    FROM bank_marketing_raw

    GROUP BY job
)

SELECT
    j.job,
    j.total_records,
    j.subscriptions,

    ROUND(
        j.job_conversion_rate,
        2
    ) AS conversion_rate_pct,

    ROUND(
        o.overall_conversion_rate,
        2
    ) AS overall_conversion_rate_pct,

    ROUND(
        j.job_conversion_rate - o.overall_conversion_rate,
        2
    ) AS difference_from_overall_pct_points

FROM job_performance j

CROSS JOIN overall_performance o

ORDER BY
    difference_from_overall_pct_points DESC;



-- ============================================================
-- 4. Month-over-month change in conversion rate
-- Demonstrates LAG()
-- ============================================================

WITH monthly_performance AS (

    SELECT
        contact_month,

        CASE contact_month
            WHEN 'jan' THEN 1
            WHEN 'feb' THEN 2
            WHEN 'mar' THEN 3
            WHEN 'apr' THEN 4
            WHEN 'may' THEN 5
            WHEN 'jun' THEN 6
            WHEN 'jul' THEN 7
            WHEN 'aug' THEN 8
            WHEN 'sep' THEN 9
            WHEN 'oct' THEN 10
            WHEN 'nov' THEN 11
            WHEN 'dec' THEN 12
        END AS month_number,

        COUNT(*) AS total_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS subscriptions,

        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS conversion_rate

    FROM bank_marketing_raw

    GROUP BY contact_month
),

monthly_comparison AS (

    SELECT
        contact_month,
        month_number,
        total_records,
        subscriptions,
        conversion_rate,

        LAG(conversion_rate) OVER (
            ORDER BY month_number
        ) AS previous_month_conversion_rate

    FROM monthly_performance
)

SELECT
    contact_month,
    total_records,
    subscriptions,

    ROUND(
        conversion_rate,
        2
    ) AS conversion_rate_pct,

    ROUND(
        previous_month_conversion_rate,
        2
    ) AS previous_month_conversion_rate_pct,

    ROUND(
        conversion_rate - previous_month_conversion_rate,
        2
    ) AS change_from_previous_month_pct_points

FROM monthly_comparison

ORDER BY month_number;



-- ============================================================
-- 5. Cumulative campaign records and subscriptions by month
-- Demonstrates SUM() as a window function
-- ============================================================

WITH monthly_totals AS (

    SELECT
        contact_month,

        CASE contact_month
            WHEN 'jan' THEN 1
            WHEN 'feb' THEN 2
            WHEN 'mar' THEN 3
            WHEN 'apr' THEN 4
            WHEN 'may' THEN 5
            WHEN 'jun' THEN 6
            WHEN 'jul' THEN 7
            WHEN 'aug' THEN 8
            WHEN 'sep' THEN 9
            WHEN 'oct' THEN 10
            WHEN 'nov' THEN 11
            WHEN 'dec' THEN 12
        END AS month_number,

        COUNT(*) AS monthly_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS monthly_subscriptions

    FROM bank_marketing_raw

    GROUP BY contact_month
)

SELECT
    contact_month,
    monthly_records,
    monthly_subscriptions,

    SUM(monthly_records) OVER (
        ORDER BY month_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_records,

    SUM(monthly_subscriptions) OVER (
        ORDER BY month_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_subscriptions

FROM monthly_totals

ORDER BY month_number;



-- ============================================================
-- 6. Contribution of each job category to total subscriptions
-- ============================================================

WITH job_subscriptions AS (

    SELECT
        job,

        COUNT(*) AS total_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS subscriptions

    FROM bank_marketing_raw

    GROUP BY job
)

SELECT
    job,
    total_records,
    subscriptions,

    ROUND(
        100.0 * subscriptions
        / SUM(subscriptions) OVER (),
        2
    ) AS share_of_total_subscriptions_pct

FROM job_subscriptions

ORDER BY
    share_of_total_subscriptions_pct DESC;



-- ============================================================
-- 7. Conversion performance and subscription contribution
-- ============================================================

WITH segment_performance AS (

    SELECT
        job,

        COUNT(*) AS total_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS subscriptions,

        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS conversion_rate

    FROM bank_marketing_raw

    GROUP BY job
)

SELECT
    job,
    total_records,
    subscriptions,

    ROUND(
        conversion_rate,
        2
    ) AS conversion_rate_pct,

    ROUND(
        100.0 * subscriptions
        / SUM(subscriptions) OVER (),
        2
    ) AS share_of_total_subscriptions_pct,

    DENSE_RANK() OVER (
        ORDER BY conversion_rate DESC
    ) AS conversion_rank,

    DENSE_RANK() OVER (
        ORDER BY subscriptions DESC
    ) AS subscription_volume_rank

FROM segment_performance

ORDER BY conversion_rank;



-- ============================================================
-- 8. Previous campaign outcome performance within loan profile
-- Demonstrates PARTITION BY
-- ============================================================

WITH customer_profiles AS (

    SELECT
        previous_outcome,
        subscribed,

        CASE
            WHEN housing_loan = 'no'
                 AND personal_loan = 'no'
                THEN 'No Loans'

            WHEN housing_loan = 'yes'
                 AND personal_loan = 'no'
                THEN 'Housing Loan Only'

            WHEN housing_loan = 'no'
                 AND personal_loan = 'yes'
                THEN 'Personal Loan Only'

            ELSE 'Both Loans'
        END AS loan_profile

    FROM bank_marketing_raw
),

profile_performance AS (

    SELECT
        loan_profile,
        previous_outcome,

        COUNT(*) AS total_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS subscriptions,

        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS conversion_rate

    FROM customer_profiles

    GROUP BY
        loan_profile,
        previous_outcome
)

SELECT
    loan_profile,
    previous_outcome,
    total_records,
    subscriptions,

    ROUND(
        conversion_rate,
        2
    ) AS conversion_rate_pct,

    DENSE_RANK() OVER (
        PARTITION BY loan_profile
        ORDER BY conversion_rate DESC
    ) AS outcome_rank_within_loan_profile

FROM profile_performance

ORDER BY
    loan_profile,
    outcome_rank_within_loan_profile;



-- ============================================================
-- 9. Identify high-volume, above-average response segments
-- ============================================================

WITH overall_performance AS (

    SELECT
        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS overall_conversion_rate

    FROM bank_marketing_raw
),

customer_segments AS (

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

segment_performance AS (

    SELECT
        age_group,
        balance_profile,
        loan_profile,

        COUNT(*) AS total_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS subscriptions,

        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS conversion_rate

    FROM customer_segments

    GROUP BY
        age_group,
        balance_profile,
        loan_profile

    HAVING COUNT(*) >= 500
)

SELECT
    s.age_group,
    s.balance_profile,
    s.loan_profile,
    s.total_records,
    s.subscriptions,

    ROUND(
        s.conversion_rate,
        2
    ) AS conversion_rate_pct,

    ROUND(
        o.overall_conversion_rate,
        2
    ) AS overall_conversion_rate_pct,

    ROUND(
        s.conversion_rate - o.overall_conversion_rate,
        2
    ) AS difference_from_overall_pct_points

FROM segment_performance s

CROSS JOIN overall_performance o

WHERE
    s.conversion_rate > o.overall_conversion_rate

ORDER BY
    difference_from_overall_pct_points DESC;



-- ============================================================
-- 10. Campaign contact efficiency relative to first-contact
-- performance
-- Demonstrates FIRST_VALUE()
-- ============================================================

WITH contact_performance AS (

    SELECT
        CASE
            WHEN campaign_contacts = 1 THEN '1 Contact'
            WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3 Contacts'
            WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5 Contacts'
            WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10 Contacts'
            ELSE '11+ Contacts'
        END AS contact_frequency,

        CASE
            WHEN campaign_contacts = 1 THEN 1
            WHEN campaign_contacts BETWEEN 2 AND 3 THEN 2
            WHEN campaign_contacts BETWEEN 4 AND 5 THEN 3
            WHEN campaign_contacts BETWEEN 6 AND 10 THEN 4
            ELSE 5
        END AS frequency_order,

        COUNT(*) AS total_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS subscriptions,

        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS conversion_rate

    FROM bank_marketing_raw

    GROUP BY
        CASE
            WHEN campaign_contacts = 1 THEN '1 Contact'
            WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3 Contacts'
            WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5 Contacts'
            WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10 Contacts'
            ELSE '11+ Contacts'
        END,

        CASE
            WHEN campaign_contacts = 1 THEN 1
            WHEN campaign_contacts BETWEEN 2 AND 3 THEN 2
            WHEN campaign_contacts BETWEEN 4 AND 5 THEN 3
            WHEN campaign_contacts BETWEEN 6 AND 10 THEN 4
            ELSE 5
        END
),

contact_comparison AS (

    SELECT
        contact_frequency,
        frequency_order,
        total_records,
        subscriptions,
        conversion_rate,

        FIRST_VALUE(conversion_rate) OVER (
            ORDER BY frequency_order
        ) AS first_contact_conversion_rate

    FROM contact_performance
)

SELECT
    contact_frequency,
    total_records,
    subscriptions,

    ROUND(
        conversion_rate,
        2
    ) AS conversion_rate_pct,

    ROUND(
        first_contact_conversion_rate,
        2
    ) AS first_contact_conversion_rate_pct,

    ROUND(
        conversion_rate - first_contact_conversion_rate,
        2
    ) AS difference_from_first_contact_pct_points

FROM contact_comparison

ORDER BY frequency_order;