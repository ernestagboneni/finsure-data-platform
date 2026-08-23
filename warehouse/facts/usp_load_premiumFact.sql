/*
================================================================================
Script:      usp_load_premiumFact.sql
Author:      Ernest Agboneni — Phase 6
Date:        [Date]
Description: Loads premium facts into the warehouse.
Change Log:
  [Date] [Author] Initial version
================================================================================
*/
USE FSA_Warehouse;
GO      

CREATE OR ALTER PROCEDURE warehouse.usp_load_premiumFact 
    @rowCount INT OUTPUT,
    @lastSuccessTimestamp   DATETIME = NULL,
    @isIncrement            BIT = 0
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;

    BEGIN TRY
    BEGIN TRANSACTION;
    IF @isIncrement = 1
    BEGIN
      INSERT INTO FSA_Warehouse.warehouse.PremiumFact (policy_dim_key, date_dim_key, agent_dim_key, region_dim_key, policy_id, underwriter_code, payment_frequency, premium_amount_gbp, premium_variance_gbp, data_quality_flag, etl_status, source_system)
        SELECT pd.policy_dim_key,
               dd.date_dim_key,
               ad.agent_dim_key,
               rd.region_dim_key,
               pd.policy_id,
               pd.underwriter_code,
               pd.payment_frequency,
               pl.premium_amount_numeric,
               pl.premium_variance_numeric,
               pl.data_quality_flag,
               pl.etl_status,
               pl.source_system
        FROM   FSA_Staging.stg.Policies AS pl
               LEFT OUTER JOIN
               warehouse.PolicyDimension AS pd
               ON pd.policy_id = pl.policy_id
               LEFT OUTER JOIN
               warehouse.AgentDimension AS ad
               ON pl.agent_id = ad.agent_id
               LEFT OUTER JOIN
               warehouse.RegionDimension AS rd
               ON pl.region = rd.region
               LEFT OUTER JOIN
               warehouse.DateDimension AS dd
               ON pl.policy_start_date_converted = dd.date
        WHERE  pd.is_current = 1
               AND pd.effective_to IS NULL
               AND pl.policy_start_date_converted > @lastSuccessTimestamp;

        SET @rowCount = @@ROWCOUNT;
    END
    ELSE
    BEGIN
        INSERT INTO FSA_Warehouse.warehouse.PremiumFact (policy_dim_key, date_dim_key, agent_dim_key, region_dim_key, policy_id, underwriter_code, payment_frequency, premium_amount_gbp, premium_variance_gbp, data_quality_flag, etl_status, source_system)
        SELECT pd.policy_dim_key,
                   dd.date_dim_key,
                   ad.agent_dim_key,
                   rd.region_dim_key,
                   pd.policy_id,
                   pd.underwriter_code,
                   pd.payment_frequency,
                   pl.premium_amount_numeric,
                   pl.premium_variance_numeric,
                   pl.data_quality_flag,
                   pl.etl_status,
                   pl.source_system
            FROM   FSA_Staging.stg.Policies AS pl
                   LEFT OUTER JOIN
                   warehouse.PolicyDimension AS pd
                   ON pd.policy_id = pl.policy_id
                   LEFT OUTER JOIN
                   warehouse.AgentDimension AS ad
                   ON pl.agent_id = ad.agent_id
                   LEFT OUTER JOIN
                   warehouse.RegionDimension AS rd
                   ON pl.region = rd.region
                   LEFT OUTER JOIN
                   warehouse.DateDimension AS dd
                   ON pl.policy_start_date_converted = dd.date
            WHERE  pd.is_current = 1
                   AND pd.effective_to IS NULL;

            SET @rowCount = @@ROWCOUNT;
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        THROW;

    END CATCH
END

RETURN 0 
