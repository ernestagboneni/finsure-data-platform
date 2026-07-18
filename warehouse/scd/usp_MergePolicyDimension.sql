/*
================================================================================
Script:      usp_MergePolicyDimension.sql
Author:      [Your name] — Phase 5
Date:        [Date]
Description: MERGE procedure for SCD Type 2 on PolicyDimension.
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

        --------------------------------------------------------------------
        -- 1) Deduplicate source (one best row per business key)
        --    Adjust ORDER BY in ROW_NUMBER() if you have a last_modified column.
        --------------------------------------------------------------------
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

        --------------------------------------------------------------------
        -- 2) MERGE: expire current rows that changed (action = UPDATE)
        --    and insert brand-new policies (action = INSERT).
        --    Match only against current rows (is_current = 1).
        --------------------------------------------------------------------
        DECLARE @MergeOutput TABLE
        (
            MergeAction  NVARCHAR(10),
            policy_id    VARCHAR(50),
            underwriter_code CHAR(10),
            policy_type  NVARCHAR(100),
            risk_band    NVARCHAR(100),
            region       NVARCHAR(100),
            payment_frequency NVARCHAR(100)
        );

        MERGE INTO dbo.PolicyDimension AS T
        USING
        (
            SELECT * FROM #Src
        ) AS S
        ON  T.policy_id = S.policy_id
        AND T.underwriter_code = S.underwriter_code
        AND T.is_current = 1   -- match only current version
        WHEN MATCHED AND
             (
               ISNULL(T.risk_band,'') <> ISNULL(S.risk_band,'')
            OR ISNULL(T.region,'')       <> ISNULL(S.region,'')
            OR ISNULL(T.payment_frequency,'') <> ISNULL(S.payment_frequency,'')
             )
        THEN
            -- expire the current version
            UPDATE SET
                T.is_current = 0,
                T.effective_to = @effective_to
        WHEN NOT MATCHED BY TARGET
        THEN
            -- brand new policy (no prior dimension row)
            INSERT
            (
                policy_id, underwriter_code, policy_type,
                risk_band, region, payment_frequency,
                effective_from, effective_to, is_current
            )
            VALUES
            (
                S.policy_id, S.underwriter_code, S.policy_type,
                S.risk_band, S.region, S.payment_frequency,
                @AsOfDate, NULL, 1
            )
        OUTPUT
            $action,
            S.policy_id,
            S.underwriter_code,
            S.policy_type,
            S.risk_band,
            S.region,
            S.payment_frequency
        INTO @MergeOutput(MergeAction, policy_id, underwriter_code, policy_type, risk_band, region, payment_frequency);

        --------------------------------------------------------------------
        -- 3) For every UPDATE action (expired rows) we must insert a new
        --    "current" version (SCD Type 2 new row) with effective_from = @AsOfDate
        --    (MERGE did the expiry only).
        --------------------------------------------------------------------
        INSERT INTO dbo.PolicyDimension
        (
            policy_id, underwriter_code, policy_type,
            risk_band, region, payment_frequency,
            effective_from, effective_to, is_current
        )
        SELECT
            mo.policy_id, mo.underwriter_code, mo.policy_type,
            mo.risk_band, mo.region, mo.payment_frequency,
            @AsOfDate, NULL, 1
        FROM @MergeOutput mo
        WHERE mo.MergeAction = 'UPDATE';

        --------------------------------------------------------------------
        -- 4) Compute counts from the merge output and totals
        --------------------------------------------------------------------
        SELECT @expired_count = COUNT(*) FROM @MergeOutput WHERE MergeAction = 'UPDATE';
        SELECT @inserted_count =
               (SELECT COUNT(*) FROM @MergeOutput WHERE MergeAction = 'INSERT')
             + (SELECT COUNT(*) FROM @MergeOutput WHERE MergeAction = 'UPDATE'); -- updates produced new inserts too

        SET @unchanged_count = @total_source - @inserted_count;

        COMMIT TRAN;

        --------------------------------------------------------------------
        -- 5) Return summary
        --------------------------------------------------------------------
        SELECT
            @inserted_count  AS inserted_count,
            @expired_count   AS expired_count,
            @unchanged_count AS unchanged_count,
            @total_source    AS total_source_rows,
            @AsOfDate        AS as_of_date;

        -- cleanup
        DROP TABLE IF EXISTS #Src;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        DROP TABLE IF EXISTS #Src;
        THROW;
    END CATCH
END;
GO