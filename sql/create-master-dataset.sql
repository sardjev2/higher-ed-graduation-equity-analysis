-- ============================================================================
-- Graduation Equity Analysis - Data Pipeline
-- Author: Alex Sardjev
-- Note: This script assumes cleaned source tables have already been imported:
-- institutions, graduation_rates_clean, pell_grad_rates,
-- outcome_measures_clean, financial_aid_clean, completions_clean
-- ============================================================================

-- 1. Clean Pell / Non-Pell Graduation Rates

DROP TABLE IF EXISTS pell_grad_rates_clean;

CREATE TABLE pell_grad_rates_clean AS
SELECT
    unit_id,

    -- Graduation rates
    (pell_completions::float / NULLIF(pell_cohort, 0)) AS grad_rate_pell,
    (non_pell_completions::float / NULLIF(non_pell_cohort, 0)) AS grad_rate_non_pell

FROM pell_grad_rates
WHERE cohort_type = 1;

-- Filter to first-time, full-time cohorts only


-- 2. Build Master Dataset

DROP TABLE IF EXISTS master_dataset;

CREATE TABLE master_dataset AS
SELECT
    i.unit_id,
    i.institution_name,
    i.state,
    i.control,
    i.level,

    -- Overall graduation rates
    g.grad_rate,
    g.grad_rate_6yr_ba,
    g.grad_rate_men,
    g.grad_rate_women,
    g.grad_rate_pell AS grad_rate_pell_gr,

    -- Pell vs Non-Pell (constructed)
    p.grad_rate_pell AS grad_rate_pell_ssl,
    p.grad_rate_non_pell,
    (p.grad_rate_non_pell - p.grad_rate_pell) AS equity_gap,

    -- Completion timeline
    o.completion_4yr,
    o.completion_6yr,
    o.completion_8yr,
    o.bach_4yr_rate,
    o.bach_6yr_rate,
    o.bach_8yr_rate,

    -- Financial context
    f.pell_pct,
    f.loan_pct,
    f.avg_debt,

    -- Size filter variable
    c.total_completions

FROM institutions i
LEFT JOIN graduation_rates_clean g 
    ON i.unit_id = g.unit_id
LEFT JOIN pell_grad_rates_clean p 
    ON i.unit_id = p.unit_id
LEFT JOIN outcome_measures_clean o 
    ON i.unit_id = o.unit_id
LEFT JOIN financial_aid_clean f 
    ON i.unit_id = f.unit_id
LEFT JOIN completions_clean c 
    ON i.unit_id = c.unit_id;


-- 3. Export for Tableau

-- Export final dataset for visualization
-- (Run in psql)

-- \copy master_dataset TO 'path/to/master_dataset.csv' WITH CSV HEADER;
