/*
================================================================================
Script:      usp_ETL_RunEnd.sql
Author:      Ernest Agboneni — Phase 6
Date:        18/07/2026
Description: Ends the audit log process.
Change Log:
  [Date] [Author] Initial version
================================================================================
*/
USE FSA_Audit;
GO
CREATE OR ALTER PROCEDURE audit.usp_ETL_RunEnd
    @RunID           INT,
    @Status          NVARCHAR(20),           --     | 'FAILED' | 'PARTIAL'
    @RowsProcessed   INT = NULL, -- dimpolicyCount 
    @RowsRejected    INT = NULL,
    @ErrorMessage    NVARCHAR(500) = NULL,
    @DimAgentCount   INT = NULL, -- dimAgentCount
    @DimRegionCount   INT = NULL, -- dimRegionCount
    @StagingClaimsCount   INT = NULL, -- stagingClaimsCount
    @StagingPoliciesCount   INT = NULL, -- stagingPoliciesCount
    @StagingGeneralLedgerCount   INT = NULL,  -- stagingGeneralLedgerCount
    @StagingPaymentsCount   INT = NULL,  -- stagingPaymentsCount
    @premiumFactCount   INT = NULL, --  premiumsFactCount
    @claimFactCount   INT = NULL  --    claimsFactCount

AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @ts_end DATETIME2(3) = GETDATE();

        -- Check existence first to provide clear error routing
        IF NOT EXISTS (SELECT 1 FROM audit.ETL_RunLog WHERE run_id = @RunID)
        BEGIN
            DECLARE @ErrTxt NVARCHAR(255) = 'audit.usp_ETL_RunEnd: RunID ' + CAST(@RunID AS VARCHAR(10)) + ' does not exist.';
            THROW 51000, @ErrTxt, 1;
        END
   
            UPDATE audit.ETL_RunLog
            SET
                status = @Status,
                rows_processed = ISNULL(@RowsProcessed, rows_processed),
                rows_rejected  = ISNULL(@RowsRejected, rows_rejected),
                error_message = @ErrorMessage,
                dimAgentCount = ISNULL(@DimAgentCount, dimAgentCount),
                dimRegionCount = ISNULL(@DimRegionCount, dimRegionCount),
                dimPolicyCount = ISNULL(@RowsProcessed, dimPolicyCount) ,
                stagingClaimsCount = ISNULL(@StagingClaimsCount, stagingClaimsCount),
                stagingPoliciesCount = ISNULL(@StagingPoliciesCount, stagingPoliciesCount),
                stagingGeneralLedgerCount = ISNULL(@StagingGeneralLedgerCount, stagingGeneralLedgerCount),
                stagingPaymentsCount = ISNULL(@StagingPaymentsCount, stagingPaymentsCount),
                premiumsFactCount = ISNULL(@premiumFactCount, premiumsFactCount),
                claimsFactCount = ISNULL(@claimFactCount, claimsFactCount),
                duration_seconds =
                CASE
                    WHEN start_timestamp IS NOT NULL THEN DATEDIFF(SECOND, start_timestamp, @ts_end)
                    ELSE NULL
                END,
                end_timestamp = @ts_end
           WHERE run_id = @RunID;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO