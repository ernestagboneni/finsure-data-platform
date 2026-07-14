/*
================================================================================
Script:      usp_MergePolicyDimension.sql
Author:      [Your name] — Phase 5
Date:        [Date]
Description: NOT MERGE procedure for SCD Type 2 on PolicyDimension.
             Called by etl_incremental_load SSIS package nightly.
Change Log:
  09/07/2026 Ernest Agboneni Initial version
================================================================================
*/
USE FSA_Warehouse;
GO

CREATE OR ALTER PROCEDURE usp_MergePolicyDimension
    @AsOfDate DATE = NULL    -- defaults to today
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @effective_to DATE,
        @inserted_count INT = 0,
        @expired_count  INT = 0,
        @unchanged_count INT = 0,
        @total_source INT = 0;

    SET @AsOfDate = ISNULL(@AsOfDate, CAST(GETDATE() AS DATE));
    SET @effective_to = DATEADD(day, -1, @AsOfDate);

    BEGIN TRY
        BEGIN TRAN;

        -- 1) Materialise deduplicated source (one row per business key)
        IF OBJECT_ID('tempdb..#Src') IS NOT NULL DROP TABLE #Src;
        SELECT
            TRIM(p.policy_id)         AS policy_id,
            TRIM(p.underwriter_code)  AS underwriter_code,
            TRIM(p.policy_type)       AS policy_type,
            TRIM(p.risk_band)         AS risk_band,
            TRIM(p.region)            AS region,
            TRIM(p.payment_frequency) AS payment_frequency
        INTO #Src
        FROM FSA_Staging.stg.policies p
        -- If duplicates exist, use ROW_NUMBER to pick the preferred row (uncomment and adapt):
        --;WITH src AS (SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.policy_id, p.underwriter_code ORDER BY p.last_modified DESC) rn FROM FSA_Staging.stg.policies p)
        --SELECT ... FROM src WHERE rn = 1

        SELECT @total_source = COUNT(*) FROM #Src;

        -- 2) Current rows in dimension
        IF OBJECT_ID('tempdb..#Cur') IS NOT NULL DROP TABLE #Cur;
        SELECT pd.policy_id, pd.underwriter_code, pd.risk_band, pd.region, pd.payment_frequency
        INTO #Cur
        FROM dbo.PolicyDimension pd
        WHERE pd.is_current = 1;

        -- 3) Changed rows: business key exists and any tracked attribute differs (NULL-safe)
        IF OBJECT_ID('tempdb..#Changed') IS NOT NULL DROP TABLE #Changed;
        SELECT s.*
        INTO #Changed
        FROM #Src s
        INNER JOIN #Cur c
            ON s.policy_id = c.policy_id
           AND s.underwriter_code = c.underwriter_code
        WHERE ISNULL(s.risk_band,'') <> ISNULL(c.risk_band,'')
           OR ISNULL(s.region,'') <> ISNULL(c.region,'')
           OR ISNULL(s.payment_frequency,'') <> ISNULL(c.payment_frequency,'');

        -- 4) Expire current rows for changed set
        IF EXISTS (SELECT 1 FROM #Changed)
        BEGIN
            UPDATE pd
            SET is_current = 0,
                effective_to = @effective_to
            FROM dbo.PolicyDimension pd
            INNER JOIN #Changed ch
                ON pd.policy_id = ch.policy_id
               AND pd.underwriter_code = ch.underwriter_code
            WHERE pd.is_current = 1;

            SET @expired_count = @@ROWCOUNT;
        END

        -- 5) Insert new versions for changed rows
        IF EXISTS (SELECT 1 FROM #Changed)
        BEGIN
            INSERT INTO dbo.PolicyDimension
            (
                policy_id, underwriter_code, policy_type,
                risk_band, region, payment_frequency,
                effective_from, effective_to, is_current
            )
            SELECT
                ch.policy_id, ch.underwriter_code, ch.policy_type,
                ch.risk_band, ch.region, ch.payment_frequency,
                @AsOfDate, NULL, 1
            FROM #Changed ch;

            SET @inserted_count = @inserted_count + @@ROWCOUNT;
        END

        -- 6) Insert brand-new policies (no historical record exists)
        IF OBJECT_ID('tempdb..#New') IS NOT NULL DROP TABLE #New;
        SELECT s.*
        INTO #New
        FROM #Src s
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.PolicyDimension pd
            WHERE pd.policy_id = s.policy_id
              AND pd.underwriter_code = s.underwriter_code
        );

        IF EXISTS (SELECT 1 FROM #New)
        BEGIN
            INSERT INTO dbo.PolicyDimension
            (
                policy_id, underwriter_code, policy_type,
                risk_band, region, payment_frequency,
                effective_from, effective_to, is_current
            )
            SELECT
                n.policy_id, n.underwriter_code, n.policy_type,
                n.risk_band, n.region, n.payment_frequency,
                @AsOfDate, NULL, 1
            FROM #New n;

            SET @inserted_count = @inserted_count + @@ROWCOUNT;
        END

        -- 7) Unchanged count: source rows matched current and not in changed set
        SELECT @unchanged_count =
            COUNT(*)
        FROM #Src s
        INNER JOIN #Cur c
            ON s.policy_id = c.policy_id
           AND s.underwriter_code = c.underwriter_code
        WHERE NOT EXISTS (
            SELECT 1 FROM #Changed ch
            WHERE ch.policy_id = s.policy_id
              AND ch.underwriter_code = s.underwriter_code
        );

        COMMIT TRAN;

        -- Return summary
        SELECT
            @inserted_count AS inserted_count,
            @expired_count  AS expired_count,
            @unchanged_count AS unchanged_count,
            @total_source   AS total_source_rows,
            @AsOfDate       AS as_of_date;

        -- cleanup
        DROP TABLE IF EXISTS #Src;
        DROP TABLE IF EXISTS #Cur;
        DROP TABLE IF EXISTS #Changed;
        DROP TABLE IF EXISTS #New;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        DROP TABLE IF EXISTS #Src;
        DROP TABLE IF EXISTS #Cur;
        DROP TABLE IF EXISTS #Changed;
        DROP TABLE IF EXISTS #New;
        THROW;
    END CATCH
END;
GO