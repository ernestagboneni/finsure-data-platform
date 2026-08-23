/****************************************************************************************
Procedure Name : dbo.usp_TemplateProcedure
Author         : <Author Name>
Created Date   : <YYYY-MM-DD>

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

CREATE OR ALTER PROCEDURE dbo.usp_TemplateProcedure
(
    @Parameter1 INT,
    @Parameter2 VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        ---------------------------------------------------------------------
        -- Main Logic
        ---------------------------------------------------------------------

        SELECT
            @Parameter1 AS Parameter1,
            @Parameter2 AS Parameter2;

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

        /*
        Alternative (legacy approach):
        RAISERROR (
            'Error %d in procedure %s at line %d: %s',
            @ErrorSeverity,
            @ErrorState,
            @ErrorNumber,
            @ErrorProcedure,
            @ErrorLine,
            @ErrorMessage
        );
        */

    END CATCH;
END;
GO