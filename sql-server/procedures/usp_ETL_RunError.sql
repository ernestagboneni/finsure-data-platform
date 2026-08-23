/*
================================================================================
Script:      usp_ETL_RunError.sql
Author:      Ernest Agboneni — Phase 6
Date:        18/07/2026
Description: Logs errors in the audit process.
Change Log:
  [Date] [Author] Initial version
================================================================================
*/
USE FSA_Audit;
GO
CREATE OR ALTER PROCEDURE audit.usp_ETL_RunError
    @RunID           INT,
    @Status          NVARCHAR(20),           --     | 'FAILED' | 'PARTIAL'
    @ErrorMessage    NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @ts_end DATETIME2(3) = GETDATE();

        UPDATE audit.ETL_RunLog
        SET
            status = @Status,
            error_message = @ErrorMessage,
            duration_seconds =
                CASE
                    WHEN start_timestamp IS NOT NULL THEN DATEDIFF(SECOND, start_timestamp, @ts_end)
                    ELSE NULL
                END
        WHERE run_id = @RunID;

        IF @@ROWCOUNT = 0
            THROW 51000, 'usp_ETL_RunError: specified RunID not found.', 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO