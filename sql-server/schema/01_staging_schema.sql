
/******************************************************************************************
    Script Name   : <name_of_script>.sql
    Purpose       : Create database schemas
    Author        : Ernest Agboneni
    Created On    : 2026-06-21
    
    Change Log:
    ---------------------------------------------------------------------------------------
    Date        Author              Description
    ----------  ------------------  -------------------------------------------------------
    2026-06-21  Ernest Agboneni     Initial version
******************************************************************************************/


-- SCHEMA stg
IF SCHEMA_ID(N'stg') IS NULL
BEGIN
	BEGIN TRY
		CREATE SCHEMA stg; 
		PRINT N'Created schema stg'
	END TRY
	BEGIN CATCH
		PRINT N'Erfror creating schema: ' + ERROR_MESSAGE()
	END CATCH
END;

