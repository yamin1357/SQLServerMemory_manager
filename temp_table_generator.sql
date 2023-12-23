--DROP TABLE tempdb.dbo.SetMemoryMaxMinTbl 


--IF 
-- ( NOT EXISTS 
--   (select object_id from sys.objects where object_id = OBJECT_ID(N'##SetMemoryMaxMinTbl') and type = 'U')
-- )
--BEGIN

--CREATE TABLE ##SetMemoryMaxMinTbl
--(
--    ID INT PRIMARY KEY,
--    Lock BIT,
--	CreateDate DATETIME,
--	ModifiedDate DATETIME,
--);
--INSERT INTO ##SetMemoryMaxMinTbl (ID, Lock, CreateDate)
--VALUES (1, 0, GETDATE());
--END;


---- ##################### Generate table if not exists 
--IF
--(NOT EXISTS (SELECT object_id
--  FROM sys.objects
--  WHERE object_id=OBJECT_ID( N'[tempdb].[dbo].[SetMemoryMaxMinTbl]' )
--		AND type='U'))
--BEGIN

--	CREATE TABLE [tempdb].[dbo].[SetMemoryMaxMinTbl]
--	(
--	  ID		   INT PRIMARY KEY,
--	  Lock		   BIT,
--	  CreateDate   DATETIME,
--	  ModifiedDate DATETIME,);

--	INSERT INTO [tempdb].[dbo].[SetMemoryMaxMinTbl]
--	(ID,
--	 Lock,
--	 CreateDate)
--	VALUES
--	(
--	  1, 0, GETDATE( ));
--END;
---- ##################### Generate table if not exists 

--IF (EXISTS (SELECT*
--  FROM INFORMATION_SCHEMA.TABLES
--  WHERE TABLE_SCHEMA='dbo'
--		AND table_name='SetMemoryMaxMinTbl'))
--BEGIN
--	PRINT 'Database Table Exists'
--END;
--ELSE
--BEGIN
--	PRINT 'No Table in database'

--	CREATE TABLE [tempdb].[dbo].[SetMemoryMaxMinTbl]
--	(
--	  ID		   INT PRIMARY KEY,
--	  Lock		   BIT,
--	  CreateDate   DATETIME,
--	  ModifiedDate DATETIME,);

--	INSERT INTO [tempdb].[dbo].[SetMemoryMaxMinTbl]
--	(ID,
--	 Lock,
--	 CreateDate)
--	VALUES
--	(
--	  1, 0, GETDATE( ));
--END;


IF OBJECT_ID('tempdb.dbo.SetMemoryMaxMinTbl') IS NOT NULL
   BEGIN
      PRINT 'Database Table Exists'
   END;
ELSE
   BEGIN
      PRINT 'No Table in database'
	CREATE TABLE [tempdb].[dbo].[SetMemoryMaxMinTbl]
	(
	  ID		   INT PRIMARY KEY,
	  Lock		   BIT,
	  CreateDate   DATETIME,
	  ModifiedDate DATETIME,);

	INSERT INTO [tempdb].[dbo].[SetMemoryMaxMinTbl]
	(ID,
	 Lock,
	 CreateDate)
	VALUES
	(
	  1, 0, GETDATE( ));
   END;


SELECT*
FROM tempdb.dbo.SetMemoryMaxMinTbl

