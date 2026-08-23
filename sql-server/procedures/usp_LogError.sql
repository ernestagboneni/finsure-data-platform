/****************************************************************************************
Procedure Name : audit.usp_LogError
Author         : Ernest Agboneni
Created Date   : 2026-07-25

Description:
    <Brief description of the purpose of this stored procedure>

Parameters:
    @Parameter1 INT          - Description
    @Parameter2 VARCHAR(100) - Description

Change Log:
-----------------------------------------------------------------------------------------
Date         Author           Change Description
------------ ---------------- ----------------------------------------------
YYYY-MM-DD   <Author Name>    Initial creation
YYYY-MM-DD   <Author Name>    <Change description>
****************************************************************************************/
USE FSA_Audit;
GO

CREATE OR ALTER PROCEDURE audit.usp_LogError
(
    @package_name       NVARCHAR(50) ,
    @task_name          NVARCHAR(50) ,
    @error_code         INT ,
    @error_description  NVARCHAR(500)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
    BEGIN TRANSACTION
    ---------------------------------------------------------------------
    -- Main Logic
    ---------------------------------------------------------------------
                
        INSERT INTO audit.ErrorLog (
            package_name ,
            task_name ,
            error_code ,
            error_description )
        SELECT 
            @package_name ,   
            @task_name ,   
            @error_code ,      
            @error_description

    COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ---------------------------------------------------------------------
        -- Error Handling
        ---------------------------------------------------------------------

        DECLARE
            @ErrorNumber    INT             = ERROR_NUMBER(),
            @ErrorSeverity  INT             = ERROR_SEVERITY(),
            @ErrorState     INT             = ERROR_STATE(),
            @ErrorProcedure NVARCHAR(128)   = ERROR_PROCEDURE(),
            @ErrorLine      INT             = ERROR_LINE(),
            @ErrorMessage   NVARCHAR(4000)  = ERROR_MESSAGE();

        -- Optional: Log error to an audit/error table here

        THROW;

    END CATCH;
END;
GO