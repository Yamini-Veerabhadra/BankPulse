-- BankPulse: PostgreSQL-only runtime assertions
-- Execute AFTER importing the original CSV into bank_marketing_raw.
-- Raises an exception (and a nonzero psql exit with ON_ERROR_STOP=1) on any mismatch.
DO $$
DECLARE
    total_records BIGINT;
    subscription_records BIGINT;
    invalid_targets BIGINT;
    unknown_contact_records BIGINT;
    unknown_contact_yes BIGINT;
    manager_records BIGINT;
    manager_yes BIGINT;
    student_records BIGINT;
    student_yes BIGINT;
    previous_success_records BIGINT;
    previous_success_yes BIGINT;
    first_contact_records BIGINT;
    first_contact_yes BIGINT;
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE subscribed = 'yes'),
           COUNT(*) FILTER (WHERE subscribed IS NULL OR subscribed NOT IN ('yes','no'))
      INTO total_records, subscription_records, invalid_targets
      FROM bank_marketing_raw;
    IF total_records <> 45211 OR subscription_records <> 5289 OR invalid_targets <> 0 THEN
        RAISE EXCEPTION 'Baseline mismatch: rows %, yes %, invalid %',
            total_records, subscription_records, invalid_targets;
    END IF;

    SELECT COUNT(*), COUNT(*) FILTER (WHERE subscribed = 'yes')
      INTO unknown_contact_records, unknown_contact_yes
      FROM bank_marketing_raw WHERE contact_type = 'unknown';
    IF unknown_contact_records <> 13020 OR unknown_contact_yes <> 530 THEN
        RAISE EXCEPTION 'Unknown contact mismatch: rows %, yes %',
            unknown_contact_records, unknown_contact_yes;
    END IF;

    SELECT COUNT(*), COUNT(*) FILTER (WHERE subscribed = 'yes')
      INTO manager_records, manager_yes
      FROM bank_marketing_raw WHERE job = 'management';
    IF manager_records <> 9458 OR manager_yes <> 1301 THEN
        RAISE EXCEPTION 'Management mismatch: rows %, yes %', manager_records, manager_yes;
    END IF;

    SELECT COUNT(*), COUNT(*) FILTER (WHERE subscribed = 'yes')
      INTO student_records, student_yes
      FROM bank_marketing_raw WHERE job = 'student';
    IF student_records <> 938 OR student_yes <> 269 THEN
        RAISE EXCEPTION 'Student mismatch: rows %, yes %', student_records, student_yes;
    END IF;

    SELECT COUNT(*), COUNT(*) FILTER (WHERE subscribed = 'yes')
      INTO previous_success_records, previous_success_yes
      FROM bank_marketing_raw WHERE previous_outcome = 'success';
    IF previous_success_records <> 1511 OR previous_success_yes <> 978 THEN
        RAISE EXCEPTION 'Previous success mismatch: rows %, yes %',
            previous_success_records, previous_success_yes;
    END IF;

    SELECT COUNT(*), COUNT(*) FILTER (WHERE subscribed = 'yes')
      INTO first_contact_records, first_contact_yes
      FROM bank_marketing_raw WHERE campaign_contacts = 1;
    IF first_contact_records <> 17544 OR first_contact_yes <> 2561 THEN
        RAISE EXCEPTION 'One contact mismatch: rows %, yes %',
            first_contact_records, first_contact_yes;
    END IF;

    RAISE NOTICE 'PASS: PostgreSQL dataset totals and 6 key business indicators reconcile';
END $$;

-- Explicitly fail if groups unexpectedly lose or duplicate rows.
DO $$
DECLARE
    n BIGINT;
    s BIGINT;
    base_n BIGINT;
    base_s BIGINT;
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE subscribed = 'yes')
      INTO base_n, base_s FROM bank_marketing_raw;

    SELECT SUM(n_records), SUM(n_yes) INTO n, s FROM (
        SELECT COUNT(*) n_records, COUNT(*) FILTER (WHERE subscribed = 'yes') n_yes
        FROM bank_marketing_raw GROUP BY job
    ) a;
    IF n <> base_n OR s <> base_s THEN RAISE EXCEPTION 'Job partition mismatch'; END IF;

    SELECT SUM(n_records), SUM(n_yes) INTO n, s FROM (
        SELECT COUNT(*) n_records, COUNT(*) FILTER (WHERE subscribed = 'yes') n_yes
        FROM bank_marketing_raw GROUP BY previous_outcome
    ) a;
    IF n <> base_n OR s <> base_s THEN RAISE EXCEPTION 'Previous outcome partition mismatch'; END IF;

    SELECT SUM(n_records), SUM(n_yes) INTO n, s FROM (
        SELECT COUNT(*) n_records, COUNT(*) FILTER (WHERE subscribed = 'yes') n_yes
        FROM bank_marketing_raw GROUP BY
          CASE WHEN campaign_contacts = 1 THEN '1'
               WHEN campaign_contacts BETWEEN 2 AND 3 THEN '2-3'
               WHEN campaign_contacts BETWEEN 4 AND 5 THEN '4-5'
               WHEN campaign_contacts BETWEEN 6 AND 10 THEN '6-10'
               WHEN campaign_contacts >= 11 THEN '11+'
               ELSE 'Invalid' END
    ) a;
    IF n <> base_n OR s <> base_s THEN RAISE EXCEPTION 'Contact bucket partition mismatch'; END IF;

    SELECT SUM(n_records), SUM(n_yes) INTO n, s FROM (
        SELECT COUNT(*) n_records, COUNT(*) FILTER (WHERE subscribed = 'yes') n_yes
        FROM bank_marketing_raw GROUP BY
           CASE WHEN housing_loan = 'no' AND personal_loan = 'no' THEN 'Neither'
                WHEN housing_loan = 'yes' AND personal_loan = 'no' THEN 'Housing'
                WHEN housing_loan = 'no' AND personal_loan = 'yes' THEN 'Personal'
                WHEN housing_loan = 'yes' AND personal_loan = 'yes' THEN 'Both'
                ELSE 'Unknown' END
    ) a;
    IF n <> base_n OR s <> base_s THEN RAISE EXCEPTION 'Loan partition mismatch'; END IF;
    RAISE NOTICE 'PASS: PostgreSQL 4-way segmentation reconciliation';
END $$;
