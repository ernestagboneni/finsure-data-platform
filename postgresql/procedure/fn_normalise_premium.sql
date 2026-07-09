/*
================================================================================
Script:      fn_normalise_premium.sql
Author:      Ernest Agboneni — Phase 4
Date:        29/06/2026
Description: PostgreSQL equivalent of stg.usp_NormalisePremiumAmount.
             Removes currency symbols and commas from premium amounts
             and converts premium values to a standard numeric format.
Change Log:
  09/07/2026 Ernest Agboneni Initial version
================================================================================
*/


CREATE OR REPLACE FUNCTION stg.fn_normalise_premium(
    p_premium_raw VARCHAR(50)
)
RETURNS NUMERIC(18,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cleaned VARCHAR(50);
    v_result  NUMERIC(18,2);
BEGIN

    -- Remove currency symbol and thousand separators
    v_cleaned :=
        TRIM(
            REPLACE(
                REPLACE(p_premium_raw, '£', ''),
                ',',
                ''
            )
        );

    -- PostgreSQL equivalent of TRY_CAST using exception handling
    BEGIN
        v_result := v_cleaned::NUMERIC(18,2);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    RETURN v_result;

END;
$$;


/*
CROSS-PLATFORM DIFFERENCES TO DOCUMENT

1. T-SQL REPLACE
   SQL Server:
       REPLACE(column, '£', '')

   PostgreSQL:
       REPLACE(column, '£', '')

   No change required.

2. T-SQL TRIM
   SQL Server:
       TRIM(value)

   PostgreSQL:
       TRIM(value)

   No change required.

3. T-SQL TRY_CAST / TRY_CONVERT
   SQL Server:
       TRY_CAST(value AS DECIMAL(18,2))
       TRY_CONVERT(DATE, value, 120)

   PostgreSQL:
       No direct equivalent exists.
       Use explicit casting inside an EXCEPTION block.

       BEGIN
           v_result := value::NUMERIC(18,2);
       EXCEPTION
           WHEN OTHERS THEN
               RETURN NULL;
       END;

4. T-SQL CREATE OR ALTER
   SQL Server:
       CREATE OR ALTER PROCEDURE ...

   PostgreSQL:
       CREATE OR REPLACE FUNCTION ...

5. T-SQL PRINT
   SQL Server:
       PRINT 'Message'

   PostgreSQL:
       RAISE NOTICE 'Message'

6. T-SQL RAISERROR
   SQL Server:
       RAISERROR('Error', 16, 1)

   PostgreSQL:
       RAISE EXCEPTION 'Error'

7. Date Conversion
   SQL Server:
       CONVERT(VARCHAR(10), date_value, 23)

   PostgreSQL:
       TO_CHAR(date_value, 'YYYY-MM-DD')

   Alternatively:
       date_value::DATE::TEXT

8. Stored Procedure vs Function
   SQL Server:
       Procedure updates table data and prints row counts.

   PostgreSQL:
       This implementation is a reusable scalar function that
       normalises a single premium amount and returns
       NUMERIC(18,2).
*/