USE [msdb]
GO

/****** Object:  Job [sql_server_memory_manager_job]    Script Date: 11/18/2023 12:56:13 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/18/2023 12:56:13 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'sql_server_memory_manager_job', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-LMF2KT2\KhajehYar', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [bootstrapper_phase]    Script Date: 11/18/2023 12:56:14 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'bootstrapper_phase', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
IF OBJECT_ID(''tempdb.dbo.SetMemoryMaxMinTbl'') IS NOT NULL
   BEGIN
      PRINT ''Database Table Exists''
   END;
ELSE
   BEGIN
      PRINT ''No Table in database''
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
   END;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [monitor_controller]    Script Date: 11/18/2023 12:56:14 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'monitor_controller', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @strtSQL DATETIME
DECLARE @currmem INT
DECLARE @smaxmem INT
DECLARE @osmaxmm INT
DECLARE @osavlmm INT
DECLARE @start_date DATETIME
DECLARE @locker BIT

DECLARE @threshold INT
SELECT @threshold =  70
DECLARE @threshold_value INT
DECLARE @min_server_memory FLOAT 
SELECT @min_server_memory =  5859
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
	PRINT ''Current memory usage in (kb) is : '' + CAST(@currmem AS VARCHAR) 
	PRINT ''Maximum target committed in (kb) is : '' + CAST(@smaxmem AS VARCHAR)
	PRINT ''Threshold value calculated as (interger percent) :'' +  CAST(@threshold_value AS VARCHAR)
    IF @threshold_value > @threshold
		BEGIN
			IF @locker=1
				BEGIN
					DECLARE @diff INT
					SELECT @diff=DATEDIFF(MINUTE, @start_date, GETDATE())
					PRINT ''Difference time passed from threshold EXCEED :'' +  CAST(@diff AS VARCHAR)
					IF @diff > 3
						BEGIN							
							EXEC sp_configure ''show advanced options'', 1
							RECONFIGURE

							PRINT ''##RELEASE MEMORY SPACE STARTED ... AT '' + CAST(GETDATE() AS VARCHAR)
							EXEC sp_configure ''max server memory'', @min_server_memory -- 65536;  --64GB			
							RECONFIGURE
							PRINT ''##RELEASE MEMORY SPACE FINISEHD ... AT '' + CAST(GETDATE() AS VARCHAR)

							--Value to wait befor increase commit to max server memory #####
							WAITFOR DELAY ''00:00:30''; 			
			
							EXEC sp_configure ''show advanced options'', 1;  			
							RECONFIGURE

							PRINT ''##ALLOCATE MEMORY STARTED ... AT '' + CAST(GETDATE() AS VARCHAR)
							EXEC sp_configure ''max server memory'', @max_server_memory -- 65536;  --64GB			
							RECONFIGURE						
							PRINT ''##ALOCATE MEMORY FINISHED ... AT '' + CAST(GETDATE() AS VARCHAR)

							UPDATE [tempdb].[dbo].[SetMemoryMaxMinTbl] SET Lock=0, ModifiedDate = GETDATE()
		
						END
				END
			ELSE
				BEGIN
					SELECT @start_date= GETDATE( )
					UPDATE [tempdb].[dbo].[SetMemoryMaxMinTbl] SET Lock=1, CreateDate=@start_date, ModifiedDate = @start_date
					PRINT ''Memory usage EXCEED at '' + CAST(@start_date AS VARCHAR) + '' with threshold value : '' + CAST(@threshold_value AS VARCHAR)
				END
		END
END TRY  
BEGIN CATCH      
    PRINT ''EXCEPTION OCCURED AT :'' + CAST(GETDATE( ) AS VARCHAR)
END CATCH;   
GO', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'initialize_starter', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20231112, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'1d8458b9-e488-432f-bc39-18f2ea021514'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


