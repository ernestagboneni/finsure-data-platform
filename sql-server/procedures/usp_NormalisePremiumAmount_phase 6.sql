/*
================================================================================
Script:      usp_NormalisePremiumAmount.sql
Author:      [Your name] — Phase 3
Date:        [Date]
Description: Normalises the premium_amount column in stg.Policies.
             Handles two formats:
               Format 1: 1234.56          (clean — already numeric)
               Format 2: £1,234.56        (dirty — currency symbol + comma)
             Converts both to DECIMAL(18,2) in warehouse_premium_gbp.
             Logs rows that cannot be parsed to audit.DataChangeLog.
Change Log:
  29/06/2026 Ernest Agboneni Initial version
================================================================================
*/USE FSA_Staging;
GO

CREATE OR ALTER PROCEDURE stg.usp_NormalisePremiumAmount
(
      @BatchSize INT = 10000,
      @Debug BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
          @Processed INT = 0,
          @Normalized INT = 0,
          @Failed INT = 0,
          @LoopRows INT = 0,
          @UpdateRows INT = 0;

    BEGIN TRY
        PRINT CONCAT('usp_NormalisePremiumAmount START. BatchSize=', @BatchSize);

        -- Temp table with clustered index for faster joins/updates on large sets
        IF OBJECT_ID('tempdb..#Batch') IS NOT NULL DROP TABLE #Batch;
        CREATE TABLE #Batch
        (
            policy_id VARCHAR(50) NOT NULL PRIMARY KEY,
            parsed_value DECIMAL(18,2) NOT NULL
        );

        WHILE 1 = 1
        BEGIN
            -- Populate batch: compute parsed_value once per row via CROSS APPLY
            INSERT INTO #Batch (policy_id, parsed_value)
            SELECT TOP (@BatchSize)
                   p.policy_id,
                   x.parsed_value
            FROM stg.Policies AS p
            CROSS APPLY
            (
                SELECT parsed_value = COALESCE(
                    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(LTRIM(RTRIM(p.premium_amount)),'£',''),',','')),
                    TRY_CONVERT(DECIMAL(18,2), p.premium_amount)
                )
            ) AS x
            WHERE p.premium_amount IS NOT NULL
              AND x.parsed_value IS NOT NULL
              AND (
                    p.warehouse_premium_gbp IS NULL
                 OR p.warehouse_premium_gbp <> x.parsed_value
              )
            ORDER BY p.policy_id;  -- relies on policy_id ordering (your zero-padded ids are OK)

            SELECT @LoopRows = COUNT(*) FROM #Batch;
            IF @LoopRows = 0
                BREAK;

            -- Update in a small transaction
            BEGIN TRAN;
                UPDATE p
                SET warehouse_premium_gbp = b.parsed_value
                FROM stg.Policies AS p
                INNER JOIN #Batch AS b ON p.policy_id = b.policy_id;
                SET @UpdateRows = @@ROWCOUNT;
            COMMIT TRAN;

            -- totals: Processed = rows examined, Normalized = rows actually updated
            SET @Processed = @Processed + @LoopRows;
            SET @Normalized = @Normalized + ISNULL(@UpdateRows, 0);

            IF @Debug = 1
                PRINT CONCAT('BatchRows=', @LoopRows, ', Updated=', ISNULL(@UpdateRows,0));

            -- clear batch for next iteration (fast)
            TRUNCATE TABLE #Batch;
        END

        DROP TABLE #Batch;

        ------------------------------------------------------------------
        -- Log unparseable values (unchanged behavior) — log once
        ------------------------------------------------------------------
 /*
 IF OBJECT_ID('audit.DataChangeLog', 'U') IS NOT NULL
        BEGIN
            DECLARE @Inserted TABLE (LogID INT);
            INSERT INTO audit.DataChangeLog
            (
                  TableName, KeyColumn, KeyValue, ColumnName,
                  OldValue, ChangeType, ChangeDate, Notes
            )
            OUTPUT INSERTED.LogID INTO @Inserted(LogID)
            SELECT
                  'stg.Policies',
                  'policy_id',
                  CAST(p.policy_id AS NVARCHAR(100)),
                  'premium_amount',
                  p.premium_amount,
                  'UNPARSEABLE',
                  SYSUTCDATETIME(),
                  'Could not parse premium_amount into DECIMAL(18,2)'
            FROM stg.Policies p
            CROSS APPLY ( SELECT cleaned_text = REPLACE(REPLACE(LTRIM(RTRIM(p.premium_amount)),'£',''),',','') ) c
            WHERE p.premium_amount IS NOT NULL
              AND TRY_CONVERT(DECIMAL(18,2), c.cleaned_text) IS NULL
              AND TRY_CONVERT(DECIMAL(18,2), p.premium_amount) IS NULL
              AND (p.warehouse_premium_gbp IS NULL OR p.warehouse_premium_gbp = 0)
              AND NOT EXISTS
              (
                    SELECT 1
                    FROM audit.DataChangeLog d
                    WHERE d.TableName = 'stg.Policies'
                      AND d.KeyColumn = 'policy_id'
                      AND d.KeyValue = CAST(p.policy_id AS NVARCHAR(100))
                      AND d.ColumnName = 'premium_amount'
                      AND d.ChangeType = 'UNPARSEABLE'
              );

            SELECT @Failed = COUNT(*) FROM @Inserted;
        END
        ELSE
        BEGIN
            SELECT @Failed = COUNT(policy_id)
            FROM stg.Policies p
            CROSS APPLY ( SELECT cleaned_text = REPLACE(REPLACE(LTRIM(RTRIM(p.premium_amount)),'£',''),',','') ) c
            WHERE p.premium_amount IS NOT NULL
              AND TRY_CONVERT(DECIMAL(18,2), c.cleaned_text) IS NULL
              AND TRY_CONVERT(DECIMAL(18,2), p.premium_amount) IS NULL
              AND (p.warehouse_premium_gbp IS NULL OR p.warehouse_premium_gbp = 0);

            IF @Failed > 0
                PRINT CONCAT('WARNING: audit.DataChangeLog not found. ', @Failed, ' unparseable rows identified but not logged.');
        END;
*/
        PRINT CONCAT('usp_NormalisePremiumAmount COMPLETE. Processed=', @Processed, ', Normalized=', @Normalized, ', FailedLogged=', @Failed);

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        -- bubble up error
        THROW;
    END CATCH
END;
GO