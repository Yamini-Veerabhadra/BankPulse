-- ============================================================
-- BankPulse: Campaign Performance Analysis
-- Purpose: Evaluate campaign efficiency, contact strategy,
-- timing, and response patterns to identify opportunities
-- for improving term-deposit marketing performance.
-- ============================================================


-- ============================================================
-- 1. Campaign efficiency by contact frequency
-- ============================================================

SELECT
    CASE
        WHEN campaign_contacts = 1 THEN '1 Contact'
        WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3 Contacts'
        WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5 Contacts'
        WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10 Contacts'
        ELSE '11+ Contacts'
    END AS contact_frequency,

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
    ) AS conversion_rate_pct,

    ROUND(
        AVG(campaign_contacts),
        2
    ) AS avg_contacts

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



-- ============================================================
-- 2. Subscriptions per 1,000 records by contact frequency
-- ============================================================

SELECT
    CASE
        WHEN campaign_contacts = 1 THEN '1 Contact'
        WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3 Contacts'
        WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5 Contacts'
        WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10 Contacts'
        ELSE '11+ Contacts'
    END AS contact_frequency,

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
    ) AS conversion_rate_pct,

    ROUND(
        1000.0 * SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS subscriptions_per_1000

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



-- ============================================================
-- 3. Campaign performance by contact month
-- ============================================================

SELECT
    contact_month,

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

GROUP BY contact_month

ORDER BY
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
    END;



-- ============================================================
-- 4. Rank months by observed conversion performance
-- ============================================================

WITH monthly_performance AS (

    SELECT
        contact_month,

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

    GROUP BY contact_month
)

SELECT
    RANK() OVER (
        ORDER BY conversion_rate_pct DESC
    ) AS performance_rank,

    contact_month,
    total_records,
    subscriptions,
    conversion_rate_pct

FROM monthly_performance

ORDER BY performance_rank;



-- ============================================================
-- 5. Campaign performance by contact type
-- ============================================================

SELECT
    contact_type,

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

GROUP BY contact_type

ORDER BY conversion_rate_pct DESC;



-- ============================================================
-- 6. Contact type performance by campaign frequency
-- ============================================================

WITH contact_segments AS (

    SELECT
        contact_type,
        subscribed,

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
        END AS frequency_order

    FROM bank_marketing_raw
)

SELECT
    contact_type,
    contact_frequency,

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

FROM contact_segments

GROUP BY
    contact_type,
    contact_frequency,
    frequency_order

HAVING COUNT(*) >= 100

ORDER BY
    frequency_order,
    conversion_rate_pct DESC;



-- ============================================================
-- 7. Current campaign performance by previous campaign outcome
-- ============================================================

SELECT
    previous_outcome,

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

GROUP BY previous_outcome

ORDER BY conversion_rate_pct DESC;



-- ============================================================
-- 8. Performance by previous campaign history
-- ============================================================

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

FROM campaign_history

GROUP BY campaign_history_segment

ORDER BY conversion_rate_pct DESC;



-- ============================================================
-- 9. Performance by days since previous contact
-- Only records with previous campaign contact are included.
-- ============================================================

WITH previous_contact_segments AS (

    SELECT
        subscribed,

        CASE
            WHEN days_since_previous_contact BETWEEN 0 AND 30
                THEN '0-30 Days'

            WHEN days_since_previous_contact BETWEEN 31 AND 90
                THEN '31-90 Days'

            WHEN days_since_previous_contact BETWEEN 91 AND 180
                THEN '91-180 Days'

            WHEN days_since_previous_contact BETWEEN 181 AND 365
                THEN '181-365 Days'

            ELSE '366+ Days'
        END AS previous_contact_recency,

        CASE
            WHEN days_since_previous_contact BETWEEN 0 AND 30 THEN 1
            WHEN days_since_previous_contact BETWEEN 31 AND 90 THEN 2
            WHEN days_since_previous_contact BETWEEN 91 AND 180 THEN 3
            WHEN days_since_previous_contact BETWEEN 181 AND 365 THEN 4
            ELSE 5
        END AS recency_order

    FROM bank_marketing_raw

    WHERE previous_contacts > 0
      AND days_since_previous_contact >= 0
)

SELECT
    previous_contact_recency,

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

FROM previous_contact_segments

GROUP BY
    previous_contact_recency,
    recency_order

ORDER BY recency_order;



-- ============================================================
-- 10. Descriptive analysis of call duration by outcome
--
-- IMPORTANT:
-- Contact duration is only known after a call occurs.
-- It should NOT be used as a pre-call targeting variable.
-- This query is descriptive only.
-- ============================================================

SELECT
    subscribed,

    COUNT(*) AS total_records,

    ROUND(
        AVG(contact_duration),
        2
    ) AS avg_duration_seconds,

    MIN(contact_duration) AS min_duration_seconds,

    MAX(contact_duration) AS max_duration_seconds

FROM bank_marketing_raw

GROUP BY subscribed

ORDER BY subscribed;



-- ============================================================
-- 11. Descriptive conversion by call-duration segment
--
-- IMPORTANT:
-- These results describe completed campaign interactions.
-- They must not be interpreted as a pre-call targeting rule.
-- ============================================================

WITH duration_segments AS (

    SELECT
        subscribed,

        CASE
            WHEN contact_duration < 60
                THEN 'Under 1 Minute'

            WHEN contact_duration < 180
                THEN '1-3 Minutes'

            WHEN contact_duration < 300
                THEN '3-5 Minutes'

            WHEN contact_duration < 600
                THEN '5-10 Minutes'

            ELSE '10+ Minutes'
        END AS duration_segment,

        CASE
            WHEN contact_duration < 60 THEN 1
            WHEN contact_duration < 180 THEN 2
            WHEN contact_duration < 300 THEN 3
            WHEN contact_duration < 600 THEN 4
            ELSE 5
        END AS duration_order

    FROM bank_marketing_raw
)

SELECT
    duration_segment,

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

FROM duration_segments

GROUP BY
    duration_segment,
    duration_order

ORDER BY duration_order;



-- ============================================================
-- 12. Campaign performance by day of month
-- ============================================================

SELECT
    contact_day,

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

GROUP BY contact_day

ORDER BY contact_day;



-- ============================================================
-- 13. Compare each month's conversion rate with overall
-- campaign conversion rate
-- ============================================================

WITH overall_performance AS (

    SELECT
        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS overall_conversion_rate

    FROM bank_marketing_raw
),

monthly_performance AS (

    SELECT
        contact_month,

        COUNT(*) AS total_records,

        SUM(
            CASE
                WHEN subscribed = 'yes' THEN 1
                ELSE 0
            END
        ) AS subscriptions,

        100.0 *
        SUM(CASE WHEN subscribed = 'yes' THEN 1 ELSE 0 END)
        / COUNT(*) AS monthly_conversion_rate

    FROM bank_marketing_raw

    GROUP BY contact_month
)

SELECT
    m.contact_month,
    m.total_records,
    m.subscriptions,

    ROUND(
        m.monthly_conversion_rate,
        2
    ) AS conversion_rate_pct,

    ROUND(
        o.overall_conversion_rate,
        2
    ) AS overall_conversion_rate_pct,

    ROUND(
        m.monthly_conversion_rate - o.overall_conversion_rate,
        2
    ) AS difference_from_overall_pct_points

FROM monthly_performance m

CROSS JOIN overall_performance o

ORDER BY
    difference_from_overall_pct_points DESC;