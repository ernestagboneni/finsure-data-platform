/*
================================================================================
Script:      usp_MergePolicyDimension.sql
Author:      Ernest Agboneni — Phase 5 (Optimised)
Date:        16/07/2026
Description: MERGE procedure for SCD Type 2 on PolicyDimension.
             Excludes policy_type from change tracking per business rules.
             Called by etl_incremental_load SSIS package nightly.
================================================================================
*/
USE FSA_Warehouse;
GO

CREATE OR ALTER PROCEDURE warehouse.usp_MergePolicyDimension
    @total_rows_processed INT = NULL OUTPUT , -- total rows processed from source
	@lastSuccessTimestamp	DATETIME ,
	@isIncrement	BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @effective_to DATE,
        @inserted_count INT = 0,
        @expired_count  INT = 0,
        @unchanged_count INT = 0,
        @total_source INT = 0,
        @AsOfDate DATE;

    SET @AsOfDate = ISNULL(@AsOfDate, CAST(GETDATE() AS DATE));
    SET @effective_to = DATEADD(day, -1, @AsOfDate);

    BEGIN TRY
        BEGIN TRAN;

        --------------------------------------------------------------------
        -- 1) Extract clean source data into staging temp table
        --------------------------------------------------------------------
        IF OBJECT_ID('tempdb..#Src') IS NOT NULL DROP TABLE #Src;

        CREATE TABLE #Src
        (
            policy_id         NVARCHAR(50),
            underwriter_code  NVARCHAR(50),
            policy_type       NVARCHAR(100),
            risk_band         NVARCHAR(100),
            region            NVARCHAR(100),
            payment_frequency NVARCHAR(100)
        );

        IF @isIncrement = 1
        BEGIN
            INSERT INTO #Src (policy_id, underwriter_code, policy_type, risk_band, region, payment_frequency)
            SELECT
                TRIM(p.policy_id)         AS policy_id,
                TRIM(p.underwriter_code)  AS underwriter_code,
                TRIM(p.policy_type)       AS policy_type,
                TRIM(p.risk_band)         AS risk_band,
                TRIM(p.region)            AS region,
                TRIM(p.payment_frequency) AS payment_frequency
            
            FROM FSA_Staging.stg.policies p
            WHERE p.policy_start_date_converted > @lastSuccessTimestamp
        END
        ELSE
        BEGIN
            INSERT INTO #Src (policy_id, underwriter_code, policy_type, risk_band, region, payment_frequency)
            SELECT
                TRIM(p.policy_id)         AS policy_id,
                TRIM(p.underwriter_code)  AS underwriter_code,
                TRIM(p.policy_type)       AS policy_type,
                TRIM(p.risk_band)         AS risk_band,
                TRIM(p.region)            AS region,
                TRIM(p.payment_frequency) AS payment_frequency
            FROM FSA_Staging.stg.policies p;
        END

        SELECT @total_source = COUNT(*) FROM #Src;

        --------------------------------------------------------------------
        -- 2) MERGE: expire current rows that changed (action = UPDATE)
        --    and insert brand-new policies (action = INSERT).
        --------------------------------------------------------------------
        DECLARE @MergeOutput TABLE
        (
            MergeAction  NVARCHAR(10),
            policy_id    VARCHAR(50),
            underwriter_code VARCHAR(50), -- Fixed type from CHAR(10) to prevent truncation
            policy_type  NVARCHAR(100),
            risk_band    NVARCHAR(100),
            region       NVARCHAR(100),
            payment_frequency NVARCHAR(100)
        );

        MERGE INTO warehouse.PolicyDimension AS T
        USING
        (
            SELECT * FROM #Src
        ) AS S
        ON  T.policy_id = S.policy_id
        AND T.underwriter_code = S.underwriter_code
        AND T.is_current = 1   -- match only current version
        WHEN MATCHED AND
             (
                -- policy_type intentionally excluded per business rule
                ISNULL(T.risk_band,'')         <> ISNULL(S.risk_band,'')
             OR ISNULL(T.region,'')            <> ISNULL(S.region,'')
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
        -- 3) For every UPDATE action (expired rows) insert a new "current" version
        --------------------------------------------------------------------
        INSERT INTO warehouse.PolicyDimension
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
        -- 4) Compute counts accurately
        --------------------------------------------------------------------
        SELECT @expired_count = COUNT(*) FROM @MergeOutput WHERE MergeAction = 'UPDATE';
        SELECT @inserted_count = COUNT(*) FROM @MergeOutput WHERE MergeAction = 'INSERT';
        
        -- Unchanged = total source rows minus brand new inserts and historical updates
        SET @unchanged_count = @total_source - (@inserted_count + @expired_count);

        COMMIT TRAN;

        --------------------------------------------------------------------
        -- 5) Return summary logging data to SSIS
        --------------------------------------------------------------------
        SET @total_rows_processed = @inserted_count  + @expired_count
        --SELECT
        --    @total_rows_processed  AS processed_count, -- Total new rows added to table
        --    @expired_count   AS expired_count,
        --    @unchanged_count AS unchanged_count,
        --    @total_source    AS total_source_rows,
        --    @AsOfDate        AS as_of_date;

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
