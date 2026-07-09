/*
================================================================================
Script:      usp_DeduplicatePayments.sql
Author:      Ernest Agboneni — Phase 3
Date:        01/07/2026
Description: Removes duplicate payment records from stg.Payments.
             Rule: where payment_reference appears more than once,
             KEEP the row with the earliest payment_timestamp.
             DELETE all other duplicate rows.
             Log deleted rows to audit.DataChangeLog before deletion. 
             But this version does not contain the logging implementation yet. It is a TODO for Phase 3.
Change Log:
  [Date] [Author] Initial version
  Initial version: 01/07/2026 Ernest Agboneni
  
================================================================================
*/

USE FSA_Staging;
GO

CREATE OR ALTER PROCEDURE dbo.usp_DeduplicatePayments
    @DryRun BIT = 1    -- default to dry run: 1 = report only, 0 = delete
AS
BEGIN
    DECLARE @DupRowCount INT;
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /*
    Phase 3: Implement this procedure

    STEP 1 — Identify duplicates using ROW_NUMBER()
        PARTITION BY payment_reference
        ORDER BY payment_timestamp ASC
        Rows where row_num > 1 are duplicates to delete
    */
    PRINT 'Starting duplicate payment records removal process...';
    IF (@DryRun = 1)
    BEGIN
        WITH dupCheck AS (
        SELECT payment_reference,
            policy_reference,
            payment_timestamp,
            ROW_NUMBER() OVER (PARTITION BY payment_reference ORDER BY payment_timestamp ASC) AS row_num
        FROM   stg.Payments)
        --    STEP 2 — If @DryRun = 1: report how many rows would be deleted

        SELECT @DupRowCount = COUNT(*)      
        FROM dupCheck 
        WHERE row_num > 1 ;
        PRINT CONCAT('Number of rows to be deleted: ', @DupRowCount);
    END
    ELSE
    BEGIN
    --    STEP 3 — If @DryRun = 0:
    --        a) Log to audit.DataChangeLog (required by Meridian Clause 14.3)
    --        b) DELETE duplicate rows
    --        c) Return count of deleted rows
    
        BEGIN TRANSACTION;
        BEGIN TRY
            WITH dupCheck AS (
            SELECT payment_reference,
                policy_reference,
                payment_date,
                payment_timestamp,
                payment_method,
                payment_amount_gbp,
                payment_status,
                bank_sort_code,
                bank_account_number,
                reconciled_flag,
                ROW_NUMBER() OVER (PARTITION BY payment_reference ORDER BY payment_timestamp ASC) AS row_num
            FROM   stg.Payments)
        ---- Insert into the audit log

        ---- Delete duplicate
            DELETE p
            FROM stg.Payments p
            INNER JOIN dupCheck d
                ON d.payment_reference = p.payment_reference
                AND d.payment_timestamp = p.payment_timestamp
            WHERE d.row_num > 1;
            PRINT CONCAT('Number of rows to be deleted: ', @DupRowCount);

        SET @DupRowCount = @@ROWCOUNT;
        COMMIT TRANSACTION;
        PRINT CONCAT('Number of rows to be deleted: ', @DupRowCount);
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION;
            THROW;
        END CATCH

    END

        /*
    Expected duplicate count: 247
    Run with @DryRun = 1 first, verify count = 247, then run with @DryRun = 0
    */

    PRINT 'usp_DeduplicatePayments — implement TODO above in Phase 3';
END;
GO