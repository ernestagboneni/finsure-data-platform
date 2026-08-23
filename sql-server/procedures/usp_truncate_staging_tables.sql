/*	
	Script:      usp_truncate_staging_tables.sql
	Author:      Ernest Agboneni — Phase 6
	Date:        [18/07/2026]
	Description: This stored procedure truncates all staging tables in the FSA_Staging database.
			It is used to clear out any existing data in the staging tables before loading new data.
	Change Log:
	[Date] [Author] Initial version
*/

USE [FSA_Staging];
GO
CREATE OR ALTER PROCEDURE stg.usp_truncate_staging_tables
AS
IF OBJECT_ID( 'stg.policies', 'U') IS NOT NULL
	TRUNCATE TABLE stg.policies;
IF OBJECT_ID( 'stg.claims', 'U') IS NOT NULL
	TRUNCATE TABLE stg.claims;
IF OBJECT_ID( 'stg.GeneralLedger', 'U') IS NOT NULL
	TRUNCATE TABLE stg.GeneralLedger;
IF OBJECT_ID( 'stg.payments', 'U') IS NOT NULL			
	TRUNCATE TABLE stg.payments;

RETURN 0;