-- Create database
CREATE DATABASE fsa_staging_pg;
-- Create schema
CREATE SCHEMA IF NOT EXISTS stg;

CREATE TABLE IF NOT EXISTS stg.Claims
(
    claim_reference      VARCHAR(100) NOT NULL,
    policy_reference     VARCHAR(100),
    claim_date           DATE,
    claim_type           VARCHAR(50),
    claim_status         VARCHAR(50),
    reserve_amount_gbp   NUMERIC(18,2),
    paid_amount_gbp      NUMERIC(18,2),
    handler_id           CHAR(6),
    days_open            INTEGER,
    source_system        VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS stg.GeneralLedgers
(
    gl_entry_id          VARCHAR(100) NOT NULL,
    entry_date           DATE,
    gl_account_code      VARCHAR(50),
    account_description  VARCHAR(250),
    entry_type           VARCHAR(50),
    debit_gbp            NUMERIC(18,2),
    credit_gbp           NUMERIC(18,2),
    policy_reference     VARCHAR(100),
    period               CHAR(7),
    posted_by            VARCHAR(100),
    approved             CHAR(1) DEFAULT 'N'
);

CREATE TABLE IF NOT EXISTS stg.Payments
(
    payment_reference     VARCHAR(100) NOT NULL,
    policy_reference      VARCHAR(100),
    payment_date          DATE,
    payment_timestamp     TIMESTAMP(3),
    payment_method        VARCHAR(50),
    payment_amount_gbp    NUMERIC(18,2),
    payment_status        VARCHAR(50),
    bank_sort_code        VARCHAR(20),
    bank_account_number   VARCHAR(34),
    reconciled_flag       CHAR(1) DEFAULT 'N'
);

CREATE TABLE IF NOT EXISTS stg.Policies
(
    policy_id               VARCHAR(100) NOT NULL,
    underwriter_code        CHAR(3),
    policy_type             VARCHAR(50),
    risk_band               VARCHAR(50),
    region                  VARCHAR(100),
    agent_id                VARCHAR(100),
    policy_start_date       VARCHAR(20),
    policy_end_date         VARCHAR(20),
    payment_frequency       VARCHAR(50),
    premium_amount          VARCHAR(50),
    warehouse_premium_gbp   VARCHAR(30),
    premium_variance_gbp    VARCHAR(30),
    etl_status              VARCHAR(50),
    etl_processed_week      CHAR(3),
    source_system           VARCHAR(100),
    data_quality_flag       CHAR(1) DEFAULT 'N'
);

SELECT * 
FROM pg_database
WHERE datname = 'fsa_staging_pg'
;

SELECT *
FROM information_schema.schemata
WHERE schema_name = 'stg';
;

SELECT table_catalog, table_schema, table_type
FROM information_schema.tables
WHERE table_schema = 'stg';
