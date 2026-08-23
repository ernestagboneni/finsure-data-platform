
/*
================================================================================
Script:      usp_Merge_RegionDimension.sql
Author:      Ernest Agboneni — Phase 6 
Date:        18/07/2026
Description: MERGE procedure for RegionDimension.
             Excludes region_type from change tracking per business rules.
================================================================================
*/
USE FSA_Warehouse;
GO
CREATE OR ALTER PROCEDURE warehouse.usp_Merge_RegionDimension 
	@rowCount INT OUTPUT,
	@lastSuccessTimestamp	DATETIME = NULL,
	@isIncrement	BIT = 0
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
    
	BEGIN TRY
	BEGIN TRANSACTION;
		IF OBJECT_ID('tempdb..#RegionSrc') IS NOT NULL DROP TABLE #RegionSrc;
		CREATE TABLE #RegionSrc (
		region	 nvarchar(50) NOT NULL
		);

		IF @isIncrement = 1
		BEGIN
			-- Incremental load: only include new or updated regions since the last successful timestamp
			INSERT INTO #RegionSrc (region)
			SELECT DISTINCT region
			FROM FSA_Staging.stg.Policies
			WHERE policy_start_date_converted > @lastSuccessTimestamp;
		END
		ELSE
		BEGIN
			-- Full load: include all distinct regions
			INSERT INTO #RegionSrc (region)
			SELECT DISTINCT region
			FROM FSA_Staging.stg.Policies;
		END

		MERGE INTO warehouse.RegionDimension AS t
		USING ( SELECT region FROM #RegionSrc ) AS s
		ON t.region = s.region
		WHEN NOT MATCHED BY TARGET THEN
		INSERT (region) VALUES (s.region);

		SET @rowCount = @@ROWCOUNT;

	COMMIT TRANSACTION; 
	END TRY
	BEGIN CATCH
		
		ROLLBACK TRANSACTION;
	 THROW;
	END CATCH;
END
RETURN 0 