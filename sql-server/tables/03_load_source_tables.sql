---===========================================================================================
---Load Pr staging tables so that source files and tables are the same without transformation
---===========================================================================================
PRINT '================================================================'
PRINT 'Load Pr staging tablesso that source files and tables are the same without transformation'
PRINT '================================================================'

BEGIN TRY
	TRUNCATE TABLE stg.fsa_claims_staging ;
	BULK INSERT stg.fsa_claims_staging
	FROM 'E:\Documents\finsure-data-platform\data\fsa_claims_staging.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK,
		FORMAT = 'CSV',
		FIELDQUOTE = '"'
	)
END TRY
BEGIN CATCH
	PRINT CONCAT('Error: ', ERROR_NUMBER(), ERROR_MESSAGE())
END CATCH

BEGIN TRY
	TRUNCATE TABLE stg.fsa_general_ledger;
	
	BULK INSERT stg.fsa_general_ledger
	FROM 'E:\Documents\finsure-data-platform\data\fsa_general_ledger.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK,
		FORMAT = 'CSV',
		FIELDQUOTE = '"'
	)

END TRY
BEGIN CATCH
	PRINT CONCAT('Error: ', ERROR_NUMBER(), ERROR_MESSAGE())
END CATCH

BEGIN TRY
	TRUNCATE TABLE stg.fsa_payments_staging;
	
	BULK INSERT stg.fsa_payments_staging
	FROM 'E:\Documents\finsure-data-platform\data\fsa_payments_staging.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK,
		FORMAT = 'CSV',
		FIELDQUOTE = '"'
	)

END TRY
BEGIN CATCH
	PRINT CONCAT('Error: ', ERROR_NUMBER(), ERROR_MESSAGE())
END CATCH


BEGIN TRY
	TRUNCATE TABLE stg.fsa_premiums_staging;

	BULK INSERT stg.fsa_premiums_staging
	FROM 'E:\Documents\finsure-data-platform\data\fsa_premiums_staging.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK ,
		CODEPAGE = '65001',
		FORMAT = 'CSV',
		FIELDQUOTE = '"'
	);
	
	UPDATE stg.fsa_premiums_staging
	SET    policy_id = 'POL-0124848'
	FROM   stg.fsa_premiums_staging
	WHERE  policy_id = 'POL-0049999'
	AND underwriter_code = 'AVV';

END TRY
BEGIN CATCH
	PRINT CONCAT('Error: ', ERROR_NUMBER(), ERROR_MESSAGE())
END CATCH
