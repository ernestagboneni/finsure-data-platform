SELECT * --MAX([start_timestamp]) AS [start_timestamp]
FROM [FSA_Audit].[audit].[ETL_RunLog]
WHERE status = 'SUCCESS'


select * from INFORMATION_SCHEMA.TABLES
where TABLE_SCHEMA = 'stg'


Truncate table FSA_Staging.stg.RawClaimsStaging
Truncate table FSA_Staging.stg.RawGeneralLedger
Truncate table FSA_Staging.stg.RawPaymentsStaging
Truncate table FSA_Staging.stg.RawPremiumsStaging
Truncate table FSA_Staging.stg.fsa_claims_staging
Truncate table FSA_Staging.stg.fsa_general_ledger
Truncate table FSA_Staging.stg.fsa_payments_staging
Truncate table FSA_Staging.stg.fsa_premiums_staging
Truncate table FSA_Staging.stg.Claims
Truncate table FSA_Staging.stg.GeneralLedgers
Truncate table FSA_Staging.stg.Payments
Truncate table FSA_Staging.stg.Policies

Truncate table FSA_Audit.audit.ETL_RunLog
Truncate table FSA_Audit.audit.ErrorLog
delete FSA_Warehouse.warehouse.ClaimsFact
delete FSA_Warehouse.warehouse.PremiumFact
go
Truncate table FSA_Warehouse.warehouse.PolicyDimension
Truncate table FSA_Warehouse.warehouse.DateDimension
Truncate table FSA_Warehouse.warehouse.RegionDimension
Truncate table FSA_Warehouse.warehouse.AgentDimension

drop table FSA_Warehouse.warehouse.PolicyDimension