# FinSure Data Platform Remediation & Modernisation (FSA-DPR-2025-001)

## 1. Overview

### 1.1 Problem Statement

FinSure Analytics has received a Data Quality Notice (DQN) from Meridian Insurance identifying:

- 3,847 policies with premium discrepancies greater than £500  
- Impact period: January to May 2025  
- Estimated financial exposure: £1.94 million  

Root causes identified:
- ETL failure during Weeks 9–12 (March–April 2025)  
- Reconciliation job disabled  
- Data quality inconsistencies in staging data  


### 1.2 Objectives

The system must:

1. Resolve premium discrepancies  
2. Restore reconciliation processes  
3. Implement robust data quality controls  
4. Ensure GDPR and FCA compliance  
5. Introduce engineering best practices (CI/CD, monitoring, documentation)  

### 1.3 Definitions

1.  DQN: Data Quality Notice
2.  RCA: Root Cause Analysis
3.  ETL: Extract–Transform–Load
4.  RBAC: Role-Based Access Control
5.  CI/CD: Continuous Integration / Deployment

## 2. Current System State (AS-IS)
### 2.1 Architecture

- SQL Server 2019 (on-premises)  
- SSIS-based ETL pipelines  
- Star schema data warehouse  
- Semantic layer for reporting  
- Power BI dashboards  

### 2.2 Key Failures

| Area       | Issue |
|------------|------|
| ETL        | Incremental load failing (March–April) |
| SQL Agent  | `FSA_Reconciliation_Check` job disabled |
| Data Quality | Mixed formats and duplicates in staging. SCD Type 2 not working |
| Reporting  | 3 broken semantic views |
| Security   | RBAC outdated, ex-employees have access |
| DevOps     | No CI/CD, direct production deployments |


## 3. Data Sources and Files

### 3.1 Input Files

| Dataset   | File                                   | Records  |
|-----------|----------------------------------------|----------|
| Policies  | `data/raw/fsa_policies_staging.csv`    | 124,847  |
| Premiums  | `data/raw/fsa_premiums_staging.csv`    | 124,847  |
| Claims    | `data/raw/fsa_claims_staging.csv`      | 38,214   |
| Payments  | `data/raw/fsa_payments_staging.csv`    | 89,341   |
| GL        | `data/raw/fsa_general_ledger.csv`      | 12,450   |


## 4. Functional Requirements

### 4.1 FR-01: Data Ingestion

**Description:**  
Load raw data into staging schema (`stg.*`).

**Tables:**
- `stg.Policies`
- `stg.Claims`
- `stg.Payments`
- `stg.GeneralLedger`

**Rules:**
- No transformation in staging  
- Preserve raw source values  
- Capture ETL metadata fields  

### 4.2 FR-02: Data Cleansing and Standardisation

| File     | Column               | Issue                          | Requirement |
|----------|----------------------|--------------------------------|-------------|
| Policies | `policy_start_date`  | Mixed formats                  | Convert to ISO format (YYYY-MM-DD) |
| Premiums | `premium_amount`     | Currency formatting issues     | Convert to DECIMAL (remove symbols/commas) |
| Claims   | `claim_status`       | Inconsistent capitalisation    | Standardise values (OPEN/CLOSED) |
| Payments | `payment_reference`  | ~247 duplicates                | Keep earliest `payment_timestamp` |
| GL       | `gl_account_code`    | NULL values (14 rows)          | Exclude and flag |


### 4.3 FR-03: ETL Pipeline

**Packages:**
- `etl_incremental_load`
- `etl_full_load`
- `etl_error_handler`
- `etl_audit_log`

**Requirements:**
- Rebuild incremental ETL pipeline  
- Implement row-level error handling  
- Ensure ETL logging to audit tables  
- Guarantee daily execution  

### 4.4 FR-04: Data Warehouse Processing

**Tables:**
- `warehouse.PremiumFact`
- `warehouse.ClaimsFact`
- `warehouse.PolicyDimension`

**Requirements:**
- Enforce primary/unique constraints  
- Fix SCD Type 2 implementation  
- Prevent duplicate fact records  
- Ensure referential integrity  

### 4.5 FR-05: Reconciliation Engine

**Description:**  
Compare premium values between source and warehouse.

**Rules:**
- Threshold: £500 variance  
- Flag discrepancies using `data_quality_flag`

**Requirements:**
- SQL Agent job `FSA_Reconciliation_Check` must run daily  
- Log reconciliation outputs  
- Support Root Cause Analysis (RCA)  

### 4.6 FR-06: Reporting Layer

**Fix broken semantic views:**
- `SEM.vw_MeridianPremiumSummary`
- `SEM.vw_MonthlyReconciliationView`
- `SEM.vw_AgentPerformanceDashboard`

**Requirement:**
- Update references to `premium_amount_gbp`  
- Ensure Power BI reports refresh correctly  
- Validate data consistency  

### 4.7 FR-07: Job Scheduling

**SQL Agent Jobs:**
- `FSA_Nightly_ETL`
- `FSA_Reconciliation_Check`
- `FSA_Index_Rebuild`

**Requirements:**
- Re-enable and fix reconciliation job  
- Increase job history retention (>10,000 rows)  
- Implement monitoring and alerting  

## 5. Non-Functional Requirements

### 5.1 Data Quality

- Zero unresolved discrepancies greater than £500  
- All anomalies logged and traceable  
- Full auditability of transformations  

### 5.2 Security (Data Governance and Compliance Lead Sign-Off Required)

#### NFR-SEC-01: GDPR Masking

- Table: `stg.Payments`
- Columns:
  - `bank_sort_code`
  - `bank_account_number`

**Requirement:**
- Apply Dynamic Data Masking (DDM) in all non-production environments  

#### NFR-SEC-02: RBAC Enforcement

- Remove all ex-employee access  
- Implement least privilege model  
- Perform full access review  

### 5.3 Audit Logging (CRITICAL)

**Table:** `audit.DataChangeLog`

**Required Fields:**
- changed_by  
- change_timestamp (UTC)  
- table_name  
- row_id  
- old_value  
- new_value  
- change_reason  

**Requirement:**
- Log ALL data modifications (INSERT, UPDATE, DELETE) on production warehouse tables

### 5.4 Performance

- ETL must complete within daily schedule  
- Support processing of millions of records per month  
- Maintain stable query performance  

### 5.5 DevOps / CI-CD

- All code stored in GitHub repository  
- Pull Request (PR)-based workflow  
- No direct production deployments  
- All scripts must be idempotent  

## 6. Constraints

### 6.1 Regulatory Constraints

- GDPR Article 32 — data security and masking  
- GDPR Article 5 — data accuracy  
- FCA Principle 11 — regulatory disclosure requirements  

### 6.2 Contractual Constraints

- Meridian Services Agreement Clause 14.3:
- Mandatory audit logging of all data changes  

### 6.3 Business Constraints

- Deadline: 1 September 2025 (critical)  
- Budget: £185,000  
- Revenue risk: £9.2 million contract  

## 7. Success Criteria

- Meridian Data Quality Notice resolved  
- Reconciliation runs daily without failure  
- Zero discrepancies exceeding tolerance  
- Security controls approved by governance  
- CI/CD pipeline implemented  
- Platform fully documented  

## 8. Deliverables

- Requirements document (`/docs/requirements.md`)  
- Architecture diagram (`/docs/architecture.drawio`)  
- ETL documentation  
- Security and compliance documentation  
- RCA report for Meridian  

## 9. TECHNICAL STANDARDS
### 9.1 SQL Coding Standards
- All T-SQL objects use schema prefix: dbo., stg., warehouse., audit., security.
- All stored procedures named: schema.usp_VerbObject — e.g. dbo.usp_LoadPremiumFact
- All functions named: schema.ufn_VerbObject
- All tables use PascalCase — e.g. PremiumFact, PolicyDimension
- No SELECT star in production code — explicit column lists only
- Every stored procedure has a header block: author, date, description, change log
- Every stored procedure has error handling: TRY / CATCH with RAISERROR or THROW

### 9.2 Version Control Standards
- All work in the finsure-enterprise-data-platform-simulation GitHub repository
- Branch strategy: main to release to feature or hotfix
- Every change via Pull Request — no direct pushes to main
- PR must include: description, test evidence, rollback plan
- SQL scripts must be idempotent — safe to run twice without error

### 9.3 Documentation Standards
- All architecture decisions recorded in /docs/ as Markdown
- Every SSIS package has a README in its folder
- Every SQL Agent job has a script file and description in /docs/


