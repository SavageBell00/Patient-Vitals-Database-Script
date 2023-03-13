-- Assignment02
-- Author: Dawan Savage Bell
-- W0465310
-- Date: Dec 9, 2022
-- DBAS4002

------------------------------
-- Part1 DDL--
------------------------------
-- Creating PatientVitalsDB --
------------------------------

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PatientVitalsDB')
BEGIN
	CREATE DATABASE PatientVitalsDB;
END;
GO

USE PatientVitalsDB;
GO

----------------------------
-- Creating Patient Table --
----------------------------

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Patient' and xtype='U')
BEGIN
CREATE TABLE [dbo].Patient(
PatientID int PRIMARY KEY Identity(1,1),
FirstName nvarchar(40),
LastName nvarchar(40),
HCN nvarchar(50)
)
END;
GO

---------------------------
-- Creating Vitals Table --
---------------------------

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Vitals' and xtype ='U')
BEGIN
CREATE TABLE [dbo].Vitals(
VitalsID int PRIMARY KEY IDENTITY(1,1),
PatientID int, -- Foreign Key from Patient Table
VitalsTypeID int, -- Foreign Key from VitalsType table
VitalsDT dateTime,
VitalsValue float
)
END;
GO


-------------------------------
-- Creating VitalsType Table --
-------------------------------

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='VitalsType' and xtype ='U')
BEGIN
CREATE TABLE [dbo].VitalsType(
VitalsTypeID int PRIMARY KEY IDENTITY(1,1),
VitalsTypeName nvarchar(60)
)
END;
GO

--------------------
-- DATA INSERTION --
--------------------

---------------------------------------
-- DATA INSERTION INTO PATIENT TABLE --
---------------------------------------
BEGIN TRAN
	BEGIN TRY
		INSERT INTO Patient([FirstName],[LastName],[HCN])
		VALUES
		('James','Brown','757234587'),
		('Bob','Marley','75777761');
		COMMIT TRAN
	END TRY
BEGIN CATCH
	ROLLBACK TRAN
END CATCH
GO

------------------------------------------
-- DATA INSERTION INTO Vitalstype TABLE --
------------------------------------------
BEGIN TRAN
	BEGIN TRY
		INSERT INTO [dbo].VitalsType([VitalsTypeName])
		VALUES
		('HR'),
		('Temp'),
		('MAP'),
		('SBP'),
		('DBP');
	COMMIT TRAN
	END TRY
BEGIN CATCH
	ROLLBACK TRAN
END CATCH
GO

----------------------------
-- Creating Relationships --
----------------------------

-- alterting Vitals table to add PatientID from Patient Table --
BEGIN TRAN
	BEGIN TRY
		ALTER TABLE [dbo].Vitals
		ADD CONSTRAINT FK_VITALS_PATIENTID
		FOREIGN KEY(PatientID) REFERENCES Patient(PatientID)
		ON UPDATE CASCADE
		ON DELETE CASCADE;
	COMMIT TRAN
	END TRY
BEGIN CATCH
	ROLLBACK TRAN
END CATCH
GO

-- alterting Vitals table to add VitalsTypeID from VitalsType Table --
BEGIN TRAN
	BEGIN TRY
		ALTER TABLE [dbo].Vitals
		ADD CONSTRAINT FK_VITALS_VITALSTYPEID
		FOREIGN KEY(VitalsTypeID) REFERENCES VitalsType(VitalsTypeID)
		ON UPDATE CASCADE
		ON DELETE CASCADE;
	COMMIT TRAN
	END TRY
BEGIN CATCH
	ROLLBACK TRAN
END CATCH
GO


-----------------------
-- Part2 Stored Proc --
-----------------------

CREATE OR ALTER PROCEDURE dbo.InsertIntoVitals 
	@patientID int, 
	@date date, 
	@vitalsTypeID int, 
	@vitalsValue float
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN
			INSERT INTO dbo.Vitals([PatientID],[VitalsDT],
									[VitalsTypeID],[VitalsValue])
			VALUES(@patientID, @date,@vitalsTypeID,@vitalsValue)
		IF (@@ERROR > 0) 
			BEGIN 
				ROLLBACK TRAN
			END
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS 'Unable to insert into Vitals'
	END CATCH
END;
GO


-- Inserting James Brown Vitals Data --
EXEC dbo.InsertIntoVitals 1,'01-01-2022',1,85;
EXEC dbo.InsertIntoVitals 1,'01-01-2022',2,36.1;
EXEC dbo.InsertIntoVitals 1,'01-01-2022',4,134;
EXEC dbo.InsertIntoVitals 1,'01-01-2022',5,91;
EXEC dbo.InsertIntoVitals 1,'01-03-2022',1,81;
EXEC dbo.InsertIntoVitals 1,'01-03-2022',2,38.1;
EXEC dbo.InsertIntoVitals 1,'01-03-2022',4,154;
EXEC dbo.InsertIntoVitals 1,'01-03-2022',5,97;
GO

-- Inserting Bob Marley Vitals Data --
EXEC dbo.InsertIntoVitals 2,'01-02-2022',1,67;
EXEC dbo.InsertIntoVitals 2,'01-02-2022',2,37.5;
EXEC dbo.InsertIntoVitals 2,'01-02-2022',4,145;
EXEC dbo.InsertIntoVitals 2,'01-02-2022',5,87;
EXEC dbo.InsertIntoVitals 2,'01-04-2022',1,72;
EXEC dbo.InsertIntoVitals 2,'01-04-2022',2,37.5;
EXEC dbo.InsertIntoVitals 2,'01-04-2022',4,157;
EXEC dbo.InsertIntoVitals 2,'01-04-2022',5,88;
GO


-- STORED PROCEDURE FOR MAP VALUES --
CREATE OR ALTER PROCEDURE dbo.InsertMAPIntoVitals 
	@patientID int,
	@date date
AS
BEGIN
	
	-- Try Catch for Whole Procedure
	BEGIN TRY
	BEGIN TRAN
		-- Try Catch for declaring mapID, sbpValue, dbpValue, and mapValue
		BEGIN TRY
			-- declaring and setting the mapID to its pk value from VitalsType Table
			DECLARE @mapID int  = (SELECT [VitalsTypeID] FROM VitalsType WHERE VitalsTypeName LIKE 'MAP')

			DECLARE @sbpValue float, -- for the SBP VALUE from Vitals
					@dbpValue float, -- for the DMP Value from Vitals 
					@mapValue float -- for MAP Value being inserted into Vitals
		END TRY
		BEGIN CATCH
			SELECT ERROR_MESSAGE() AS 'Error: Unable to Declare Variables'
		END CATCH

		-- Try Catch for Setting sbpValue
		BEGIN TRY
			SET @sbpValue = (SELECT [VitalsValue] FROM Vitals
							WHERE PatientID = @patientID AND 
							[VitalsDT] = @date AND 
							[VitalsTypeID] = (SELECT [VitalsTypeID] FROM VitalsType WHERE VitalsTypeName LIKE 'SBP') AND [VitalsValue] IS NOT NULL)
			
		END TRY
		BEGIN CATCH
			SELECT ERROR_MESSAGE() AS 'Error: Unable to Set SBP Value'
		END CATCH

		-- Try Catch for setting dbpValue
		BEGIN TRY
			SET @dbpValue = (SELECT [VitalsValue] FROM Vitals
							WHERE [PatientID] = @patientID AND 
							[VitalsDT] = @date AND 
							[VitalsTypeID] = (SELECT [VitalsTypeID] FROM VitalsType WHERE VitalsTypeName LIKE 'DBP') AND [VitalsValue] IS NOT NULL)
		END TRY
		BEGIN CATCH
				SELECT ERROR_MESSAGE() AS 'Error: Unable to Set DBP Value'
		END CATCH

		-- Try Catch for setting mapValue
		BEGIN TRY
			SET @mapValue = (@sbpValue +2*(@dbpValue))/3
		END TRY
		BEGIN CATCH 
					SELECT ERROR_MESSAGE() AS 'Error: Unable to Set map Value'
		END CATCH

		-- Try Catch for Inserting Values

		BEGIN TRY
			INSERT INTO dbo.Vitals([PatientID],[VitalsDT],[VitalsTypeID],[VitalsValue])
			VALUES (@patientID, @date,@mapID, @mapValue)
		END TRY
		BEGIN CATCH
			SELECT ERROR_MESSAGE() AS 'Error: Unable to Insert Values into Vitals Table'
		END CATCH

	-- Ending whole Try Catch
	IF (@@ERROR > 0 OR @mapValue IS NULL)
		BEGIN
			SELECT ERROR_MESSAGE() AS 'Error: MAP Value Cannot be Null and Date Must Already Exist.'
			ROLLBACK TRAN
		END
	COMMIT TRAN
	END TRY
	BEGIN CATCH
		SELECT 
			ERROR_NUMBER() AS 'Error Number'
			,ERROR_SEVERITY() AS 'Error Severity'
			,ERROR_STATE() AS 'Error State'
			,ERROR_PROCEDURE() AS 'Error Procedure'
			,ERROR_LINE() AS 'Error Line'
			,ERROR_MESSAGE() AS 'Error Message';

	END CATCH
END;
GO

-- Inserting James Brown MAP Values for these Dates --
EXEC dbo.InsertMAPIntoVitals 1,'2022-01-01'
EXEC dbo.InsertMAPIntoVitals 1,'2022-01-03' 
GO

-- Inserting Bob Marley Vitals Data for these Dates --
EXEC dbo.InsertMAPIntoVitals 2,'2022-01-02'
EXEC dbo.InsertMAPIntoVitals 2,'2022-01-4'
GO


-- Cursor To Show Map Values for Patients --

CREATE OR ALTER PROCEDURE dbo.PrintMapVitalsTable
AS
BEGIN
	
		-- Declaring Variables
		DECLARE @PatientName nvarchar(60)
				,@date date
				,@vitalValue float
				,@vitalID int
				,@vitalName nvarchar(50)

		-- declaring cursor
		DECLARE cursor_VitalsTable CURSOR
		FOR SELECT
				p.[FirstName] + ' ' + p.[LastName] AS patientName, [vitalsDT],vt.[VitalsTypeName] AS vitalName, [VitalsValue]
			FROM Vitals v
			INNER JOIN Patient p
			ON p.PatientID = v.PatientID
			INNER JOIN VitalsType vt
			ON vt.VitalsTypeID = v.VitalsTypeID
			WHERE vt.VitalsTypeID = (SELECT VitalsTypeID FROM VitalsType WHERE VitalsTypeName LIKE 'MAP')
			ORDER BY patientName, VitalsDT asc

		-- opening cursor
		OPEN cursor_VitalsTable
		-- Fetching the records
		FETCH NEXT FROM cursor_VitalsTable INTO 
				@PatientName, @date, 
				@VitalName, @vitalValue
	BEGIN TRAN
	BEGIN TRY

		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT ' '+@PatientName +' '+  CAST(@date AS NVARCHAR) + ' '+  @vitalName + ' ' + CAST(@vitalValue AS nvarchar)
			FETCH NEXT FROM cursor_VitalsTable INTO 
				@PatientName, @date, 
				@vitalName, @vitalValue
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
	END CATCH
	IF (@@TRANCOUNT > 0) -- if rolledback, trancount would be 0. So greater than 0 means must have succeeded.
	COMMIT TRAN
END;
CLOSE cursor_VitalsTable
DEALLOCATE cursor_VitalsTable
GO



-- CREATED A VIEW FOR QUICK REFERENCE --
CREATE OR ALTER VIEW vFullVitalsNameTypeValue
AS
	(
		SELECT [VitalsID]
			  ,[FirstName] + ' ' + [LastName] AS PatientName
			  ,VitalsTypeName
			  ,[VitalsDT] 
			  ,[VitalsValue]
		  FROM [PatientVitalsDB].[dbo].[Vitals]
		  INNER JOIN dbo.Patient 
		  ON 
		  patient.PatientID= Vitals.PatientID
		  INNER JOIN dbo.VitalsType
		  ON
		  VitalsType.VitalsTypeID = Vitals.VitalsTypeID
	)
GO


-- Procedure printing Pivot Table for Fun --
CREATE OR ALTER PROCEDURE dbo.PrintFullVitalsPivotTable
AS
BEGIN
BEGIN TRAN
	BEGIN TRY
		SELECT * FROM 
			(
				SELECT
					[PatientName],[VitalsDT],[VitalsTypeName], [VitalsValue]
				FROM
					vFullVitalsNameTypeValue
			) vt
		PIVOT(
			SUM(VitalsValue)
			FOR VitalsTypeName IN (
				 [HR]
				,[Temp]
				,[SBP]
				,[DBP]
				,[MAP]
			)
		) pivotTable
		ORDER BY [patientName],[VitalsDT]
	COMMIT
	END TRY
BEGIN CATCH
	ROLLBACK TRAN
END CATCH
END;
GO

-- Execution to Print the The Patients Full VitalsValues --
EXEC dbo.PrintFullVitalsPivotTable;

-- Execution to Print Just the Patients MAP Values --
EXEC dbo.PrintMapVitalsTable
GO