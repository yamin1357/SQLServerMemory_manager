DECLARE @strtSQL DATETIME
DECLARE @currmem INT
DECLARE @smaxmem INT
DECLARE @osmaxmm INT
DECLARE @osavlmm INT
DECLARE @start_date DATETIME
DECLARE @locker BIT

DECLARE @threshold INT
SELECT @threshold =  90
DECLARE @threshold_value INT
DECLARE @min_server_memory FLOAT 
SELECT @min_server_memory =  3906.25
DECLARE @max_server_memory FLOAT 
SELECT @max_server_memory =  7812.5

--Get start date from SetMaxMinMemoryFromTbl
SELECT @start_date=CreateDate,
	   @locker=Lock
FROM [tempdb].[dbo].[SetMemoryMaxMinTbl]

-- SQL memory
SELECT @strtSQL=sqlserver_start_time,
	   @currmem=(committed_kb/1024),
	   @smaxmem=(committed_target_kb/1024)
FROM sys.dm_os_sys_info;

BEGIN TRY  
    SELECT @threshold_value = CAST((CAST(@currmem AS FLOAT) / CAST(@smaxmem AS FLOAT)) * 100 AS INT)
	PRINT 'Current memory usage in (kb) is : ' + CAST(@currmem AS VARCHAR) 
	PRINT 'Maximum target committed in (kb) is : ' + CAST(@smaxmem AS VARCHAR)
	PRINT 'Threshold value calculated as (interger percent) :' +  CAST(@threshold_value AS VARCHAR)
    IF @threshold_value > @threshold
		BEGIN
			IF @locker=1
				BEGIN
					DECLARE @diff INT
					SELECT @diff=DATEDIFF(MINUTE, @start_date, GETDATE())
					PRINT 'Difference time passed from threshold EXCEED :' +  CAST(@diff AS VARCHAR)
					IF @diff > 3
						BEGIN							
							EXEC sp_configure 'show advanced options', 1
							RECONFIGURE

							PRINT '##RELEASE MEMORY SPACE STARTED ... AT ' + CAST(GETDATE() AS VARCHAR)
							EXEC sp_configure 'max server memory', @min_server_memory -- 65536;  --64GB			
							RECONFIGURE
							PRINT '##RELEASE MEMORY SPACE FINISEHD ... AT ' + CAST(GETDATE() AS VARCHAR)

							--Value to wait befor increase commit to max server memory #####
							WAITFOR DELAY '00:00:30'; 			
			
							EXEC sp_configure 'show advanced options', 1;  			
							RECONFIGURE

							PRINT '##ALLOCATE MEMORY STARTED ... AT ' + CAST(GETDATE() AS VARCHAR)
							EXEC sp_configure 'max server memory', @max_server_memory -- 65536;  --64GB			
							RECONFIGURE						
							PRINT '##ALOCATE MEMORY FINISHED ... AT ' + CAST(GETDATE() AS VARCHAR)

							UPDATE [tempdb].[dbo].[SetMemoryMaxMinTbl] SET Lock=0, ModifiedDate = GETDATE()
		
						END
				END
			ELSE
				BEGIN
					SELECT @start_date= GETDATE( )
					UPDATE [tempdb].[dbo].[SetMemoryMaxMinTbl] SET Lock=1, CreateDate=@start_date, ModifiedDate = @start_date
					PRINT 'Memory usage EXCEED at ' + CAST(@start_date AS VARCHAR) + ' with threshold value : ' + CAST(@threshold_value AS VARCHAR)
				END
		END
END TRY  
BEGIN CATCH      
    PRINT 'EXCEPTION OCCURED AT :' + CAST(GETDATE( ) AS VARCHAR)
END CATCH;   
GO