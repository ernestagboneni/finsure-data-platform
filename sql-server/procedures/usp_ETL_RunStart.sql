/*
================================================================================
Script:      usp_ETL_RunStart.sql
Author:      Ernest Agboneni — Phase 6
Date:        18/07/2026
Description: Starts the audit log process.
Change Log:
  [Date] [Author] Initial version
================================================================================
*/
USE FSA_Audit;
GO
CREATE OR ALTER PROCEDURE audit.usp_ETL_RunStart
    @PackageName   NVARCHAR(100),
    @TriggeredBy   NVARCHAR(50) = NULL,
    @RunID         INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @ts DATETIME2(3) = GETDATE();

        INSERT INTO audit.ETL_RunLog
        (
            package_name,
            run_date,
            run_week,
            status,
            triggered_by,
            start_timestamp
        )
        VALUES
        (
            @PackageName,
            CAST(SYSUTCDATETIME() AS DATE),
            RIGHT('00' + CAST(DATEPART(WEEK, SYSUTCDATETIME()) AS VARCHAR(3)), 3),
            'RUNNING',
            @TriggeredBy,
            @ts
        );

        SET @RunID = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO