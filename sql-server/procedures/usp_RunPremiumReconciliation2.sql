/*
================================================================================
Script:      usp_RunPremiumReconciliation2.sql
Author:      Ernest Agboneni — Phase 6
Date:        11/08/2026
Description: Logs errors in the audit process.
Change Log:
  [Date] [Author] Initial version
================================================================================
*/
USE FSA_Warehouse;
GO
CREATE OR ALTER PROCEDURE warehouse.usp_RunPremiumReconciliation2
    @MinVariance DECIMAL(18,2) = 500.00,
    @LoadDateFrom DATETIME = '2024-01-01',
    @UnderwriterCode VARCHAR(10) = 'MER'
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        -- Output reconciliation summary statistics
        ;WITH PolicyPremiums AS (
            SELECT 
                p.policy_id, 
                pf.premium_amount_gbp AS warehouse_premium_amount, 
                p.premium_amount_numeric AS premium_amount, 
                (p.premium_amount_numeric - pf.premium_amount_gbp) AS variance
            FROM warehouse.PremiumFact pf WITH (NOLOCK)
            INNER JOIN FSA_Staging.stg.Policies p WITH (NOLOCK) 
                ON pf.policy_id = p.policy_id
            WHERE p.underwriter_code = @UnderwriterCode
              AND pf.load_timestamp >= @LoadDateFrom
        )
        SELECT 
            COUNT(*) AS total_discrepant_policies,
            ISNULL(SUM(variance), 0) AS total_variance_gbp,
            ISNULL(AVG(variance), 0) AS average_variance_gbp,
            MAX(variance) AS max_variance_gbp,
            MIN(variance) AS min_variance_gbp
        FROM PolicyPremiums
        WHERE variance >= @MinVariance;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO