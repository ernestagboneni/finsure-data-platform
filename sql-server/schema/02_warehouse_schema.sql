
/******************************************************************************************
    Script Name   : <name_of_script>.sql
    Purpose       : Create database schemas
    Author        : Ernest Agboneni
    Created On    : 2026-07-16
    
    Change Log:
    ---------------------------------------------------------------------------------------
    Date        Author              Description
    ----------  ------------------  -------------------------------------------------------
    2026-07-16  Ernest Agboneni     Initial version
******************************************************************************************/

USE FSA_Warehouse
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'warehouse')
BEGIN
    EXEC('CREATE SCHEMA warehouse');
END
GO