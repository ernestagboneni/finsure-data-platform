
/*
================================================================================
Script:      usp_Merge_Agent.sql
Author:      Ernest Agboneni — Phase 6 
Date:        18/07/2026
Description: MERGE procedure for AgentDimension.
             Excludes agent_type from change tracking per business rules.
================================================================================
*/
USE FSA_Warehouse;
GO
CREATE OR ALTER PROCEDURE warehouse.usp_Merge_AgentDimension 
	@rowCount INT OUTPUT,
	@lastSuccessTimestamp	DATETIME = NULL,
	@isIncrement	BIT = 0
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
    
	BEGIN TRY
	BEGIN TRANSACTION;
		IF OBJECT_ID('tempdb..#AgentSrc') IS NOT NULL DROP TABLE #AgentSrc;
		CREATE TABLE #AgentSrc (
		agent_id nvarchar(50) NOT NULL
		);

		IF @isIncrement = 1
		BEGIN
			-- Incremental load: only include new or updated agents since the last successful timestamp
			INSERT INTO #AgentSrc (agent_id)
			SELECT DISTINCT agent_id
			FROM FSA_Staging.stg.Policies
			WHERE policy_start_date_converted > @lastSuccessTimestamp;
		END
		ELSE
		BEGIN
			-- Full load: include all distinct agents
			INSERT INTO #AgentSrc (agent_id)
			SELECT DISTINCT agent_id
			FROM FSA_Staging.stg.Policies;
		END

		MERGE INTO warehouse.AgentDimension AS t
		USING ( SELECT agent_id FROM #AgentSrc ) AS s
		ON t.agent_id = s.agent_id
		WHEN NOT MATCHED BY TARGET THEN
		INSERT (agent_id) VALUES (s.agent_id);

		SET @rowCount = @@ROWCOUNT;

	COMMIT TRANSACTION; 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
	 THROW;
	END CATCH;
END
RETURN 0 