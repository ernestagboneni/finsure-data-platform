-- Procedure: [stg].usp_RunPremiumReconciliation
-- Purpose: This stored procedure performs a premium reconciliation process by comparing the premium amounts 
--in the staging table with the warehouse premium amounts. It calculates the variance and flags any discrepancies that exceed a specified threshold.
-- Author: Ernest Agboneni | Created: 29/06/2026

CREATE OR ALTER PROCEDURE [stg].usp_RunPremiumReconciliation  

AS
BEGIN TRY

    
BEGIN TRANSACTION;

SELECT 'Running Premium Reconciliation...' AS Message;
    WITH CTE_Policies AS (
        SELECT policy_id, 
                premium_amount, 
                warehouse_premium_gbp, 
                ABS(TRY_CONVERT(DECIMAL(18,2),premium_amount) - TRY_CONVERT(DECIMAL(18,2),warehouse_premium_gbp) ) AS variance,
                CASE 
                    WHEN ABS(TRY_CONVERT(DECIMAL(18,2),premium_amount) - TRY_CONVERT(DECIMAL(18,2),warehouse_premium_gbp) ) > 500 THEN 'Y'
                    ELSE 'N'
                END AS data_quality_flag_calc
        FROM stg.Policies
        WHERE underwriter_code = 'MER'
    )

    --UPDATE stg.Policies
    --SET data_quality_flag = data_quality_flag_calc, 
    --    premium_variance_gbp = ABS(TRY_CONVERT(DECIMAL(18,2),CTE_Policies.premium_amount) - TRY_CONVERT(DECIMAL(18,2),CTE_Policies.warehouse_premium_gbp))
 
    --SELECT *
    --FROM CTE_Policies
    --INNER JOIN stg.Policies on CTE_Policies.policy_id = stg.Policies.policy_id
    --WHERE stg.Policies.policy_id = CTE_Policies.policy_id

    --PRINT 'Premium Reconciliation completed successfully. Affected rows: ' + CAST (@@ROWCOUNT AS VARCHAR(10));
   
    SELECT
        COUNT(*) AS total_policies,
        SUM(CASE WHEN data_quality_flag_calc = 'Y' THEN 1 ELSE 0 END) AS flagged_policies_with,
        SUM(CASE WHEN data_quality_flag_calc = 'N' THEN 1 ELSE 0 END) AS non_flagged_policies
    FROM CTE_Policies;

COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'An error occurred while running the Premium Reconciliation procedure. Transaction has been rolled back.';
    PRINT CONCAT('Error Details: ', ERROR_MESSAGE(), ' (Severity: ', ERROR_SEVERITY(), ', State: ', ERROR_STATE(), ')');
   
    
END CATCH;
RETURN 0 

