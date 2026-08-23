
/*
================================================================================
Script:      usp_PopulateDateDimension.sql
Author:      Ernest Agboneni — Phase 6 
Date:        19/07/2026
Description: Populate procedure for DateDimension.
================================================================================
*/
USE FSA_Warehouse;
GO

CREATE OR ALTER PROCEDURE warehouse.usp_PopulateDateDimension
    @StartDate DATE = '2015-01-01',
    @EndDate   DATE = '2035-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        -- 1) Prevent duplicates: Only insert dates that do not exist yet
        WITH DateRange AS 
        (
            SELECT TOP (DATEDIFF(DAY, @StartDate, @EndDate) + 1)
                DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @StartDate) AS DateValue
            FROM sys.all_objects a CROSS JOIN sys.all_objects b
        )
        INSERT INTO warehouse.DateDimension
        (
            [date],
            [year],
            [quarter],
            [month],
            [day],
            [week_of_year],
            [is_weekend]
        )
        SELECT
            DateValue AS [date],
            YEAR(DateValue) AS [year],
            DATEPART(QUARTER, DateValue) AS [quarter],
            MONTH(DateValue) AS [month],
            DAY(DateValue) AS [day],
            DATEPART(WEEK, DateValue) AS [week_of_year],
            -- 1 = Sunday, 7 = Saturday (Standard SQL Server DATEPART configuration)
            CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END AS [is_weekend]
        FROM DateRange dr
        WHERE NOT EXISTS (
            SELECT 1 FROM warehouse.DateDimension d 
            WHERE d.[date] = dr.DateValue
        );

        COMMIT TRAN;
    -- 2026 Pro Tip: Summary reporting can be added here if logging is required
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO
