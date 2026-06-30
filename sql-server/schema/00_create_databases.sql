
USE master;
GO

--FSA_Staging 
IF DB_ID(N'FSA_Staging') IS NULL 
BEGIN 
	BEGIN TRY 
		CREATE DATABASE [FSA_Staging]; 
		PRINT N'Created database [FSA_Staging]'; 
	END TRY 
	BEGIN CATCH 
		PRINT N'Error creating [FSA_Staging]: ' + ERROR_MESSAGE(); 
	END CATCH 
END 
ELSE PRINT N'Database [FSA_Staging] already exists.'; 
GO

-- FSA_Warehouse 
IF DB_ID(N'FSA_Warehouse') IS NULL 
BEGIN 
	BEGIN TRY 
		CREATE DATABASE [FSA_Warehouse]; 
		PRINT N'Created database [FSA_Warehouse]'; 
	END TRY 
	BEGIN CATCH 
		PRINT N'Error creating [FSA_Warehouse]: ' + ERROR_MESSAGE(); 
	END CATCH 
END 
ELSE PRINT N'Database [FSA_Warehouse] already exists.'; 
GO

-- FSA_Semantic 
IF DB_ID(N'FSA_Semantic') IS NULL 
BEGIN 
	BEGIN TRY 
		CREATE DATABASE [FSA_Semantic]; 
		PRINT N'Created database [FSA_Semantic]'; 
		END TRY 
		BEGIN CATCH 
		PRINT N'Error creating [FSA_Semantic]: ' + ERROR_MESSAGE(); 
		END CATCH 
END 
ELSE PRINT N'Database [FSA_Semantic] already exists.'; 
GO

-- FSA_Audit 
IF DB_ID(N'FSA_Audit') IS NULL 
BEGIN 
	BEGIN TRY 
		CREATE DATABASE [FSA_Audit]; 
		PRINT N'Created database [FSA_Audit]'; 
	END TRY 
	BEGIN CATCH 
		PRINT N'Error creating [FSA_Audit]: ' + ERROR_MESSAGE(); 
	END CATCH 
END 
ELSE PRINT N'Database [FSA_Audit] already exists.'; 
GO

-- FSA_Security 
IF DB_ID(N'FSA_Security') IS NULL 
BEGIN 
	BEGIN TRY 
		CREATE DATABASE [FSA_Security]; 
		PRINT N'Created database [FSA_Security]'; 
	END TRY		
	BEGIN CATCH 
		PRINT N'Error creating [FSA_Security]: ' + ERROR_MESSAGE(); 
	END CATCH 
END 
ELSE PRINT N'Database [FSA_Security] already exists.'; 
GO