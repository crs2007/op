-- =============================================
-- Author:		Sharon
-- Create date: <Create Date,,>
-- Update date: 18/02/2014 Sharon Alert Change.
--				19/10/2014 Sharon Fail-Safe
-- Description:	Create Customs Support Environment
--				exec this SP after _Admin restore
-- =============================================
CREATE PROCEDURE [Server].[usp_Shipping_SetEnvironment]	
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @schedule_id INT;
	DECLARE @ERR NVARCHAR(2048);

	IF NOT EXISTS (	SELECT TOP 1 1 FROM SYS.configurations c WHERE C.name = 'cost threshold for parallelism' AND c.[value] = 50)
	BEGIN
    	EXEC sp_configure 'cost threshold for parallelism' , 50
		RECONFIGURE WITH OVERRIDE
    END
	IF NOT EXISTS (	SELECT TOP 1 1 FROM SYS.configurations c WHERE C.name = 'optimize for ad hoc workloads' AND c.[value] = 1)
	BEGIN
		EXEC sp_configure 'optimize for ad hoc workloads' , 1
		RECONFIGURE WITH OVERRIDE
	END
	IF NOT EXISTS (	SELECT TOP 1 1 FROM SYS.configurations c WHERE C.name = 'remote admin connections' AND c.[value] = 1)
	BEGIN
		EXEC sp_configure 'remote admin connections' , 1
		RECONFIGURE WITH OVERRIDE
	END

	DECLARE @MaxServerMemory INT,
			@Operator sysname = 'DBA';
	-- Make: Designate a Fail-Safe Operator - http://msdn.microsoft.com/en-us/library/ms175514.aspx
	EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=@Operator, @notificationmethod=1
	--Set Operator Mail Recipiant
	DECLARE @MailRecipiant NVARCHAR(2048);
	SET  @Operator = 'BI';
	SELECT @MailRecipiant = Report.ufn_Mail_GetMailRecipiantByProcedureName(@Operator)
	IF NOT EXISTS(SELECT TOP 1 1 FROM [msdb].[dbo].[sysoperators] WHERE name = @Operator)
	BEGIN
    	EXEC msdb.dbo.sp_add_operator @name=@Operator, 
		@enabled=1, 
		@pager_days=0, 
		@email_address=@MailRecipiant;
    END
	ELSE
	BEGIN
		EXEC msdb.dbo.sp_update_operator @name=@Operator, 
			@enabled=1, 
			@pager_days=0, 
			@email_address=@MailRecipiant, 
			@pager_address=N'', 
			@netsend_address=N'';
	END
	SET  @Operator = 'DBA';
	SELECT @MailRecipiant = Report.ufn_Mail_GetMailRecipiantByProcedureName(@Operator)
	IF NOT EXISTS(SELECT TOP 1 1 FROM [msdb].[dbo].[sysoperators] WHERE name = @Operator)
	BEGIN
    	EXEC msdb.dbo.sp_add_operator @name=@Operator, 
		@enabled=1, 
		@pager_days=0, 
		@email_address=@MailRecipiant;
    END
	ELSE
	BEGIN
		EXEC msdb.dbo.sp_update_operator @name=@Operator, 
			@enabled=1, 
			@pager_days=0, 
			@email_address=@MailRecipiant, 
			@pager_address=N'', 
			@netsend_address=N'';
	END
	--Error Log file
	DECLARE @NumErrorLogs INT;
	SELECT @NumErrorLogs = [dbo].ufn_get_default_path (0,'NumErrorLogs');
	IF ISNULL(@NumErrorLogs,6) < 30
	BEGIN
		
		DECLARE @instance_name NVARCHAR(200) ,
				@system_instance_name NVARCHAR(200) ,
				@registry_key NVARCHAR(512) ,
				@path NVARCHAR(260) ;

		SET @instance_name = COALESCE(CONVERT(NVARCHAR(20), SERVERPROPERTY('InstanceName')),'MSSQLSERVER');

		BEGIN TRY
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL',@instance_name, @system_instance_name OUTPUT;
		SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer';

		EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', @registry_key, N'NumErrorLogs', REG_DWORD, 30;
		END TRY
		BEGIN CATCH
			SET @ERR = ERROR_MESSAGE();
			RAISERROR(@ERR,0,1)WITH NOWAIT
		END CATCH
	END
	------------------------------------------------------
	--  create alerts & error messages                  --
	------------------------------------------------------
	-- add Low System Disk Space Alert and Notification
	IF NOT EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Low System Disk Space Notification')	
	BEGIN
		EXEC msdb.dbo.sp_add_alert @name=N'Low System Disk Space Notification', 
			@message_id=0, 
			@severity=0, 
			@enabled=1, 
			@delay_between_responses=10800, 
			@include_event_description_in=1, 
			@database_name=N'', 
			@notification_message=N'', 
			@event_description_keyword=N'', 
			@performance_condition=N'', 
			@wmi_namespace=N'\\.\root\CIMV2', 
			@wmi_query=N'SELECT * FROM __instancemodificationevent within 3600 WHERE targetinstance isa ''CIM_LogicalDisk'' and targetinstance.freespace < 3221225472 and targetinstance.name=''C:''', 
			@job_id=N'00000000-0000-0000-0000-000000000000';

		EXEC msdb.dbo.sp_add_notification @alert_name=N'Low System Disk Space Notification', @operator_name=@Operator, @notification_method = 1;
	END 

	IF EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Low Disk Space Notification')	
	BEGIN
		EXEC msdb.dbo.sp_delete_alert @name=N'Low Disk Space Notification'
	END



	IF OBJECT_ID('tempdb..#DriveSpace') IS NOT NULL DROP TABLE #DriveSpace
	CREATE TABLE #DriveSpace
		  (
			DriveLetter CHAR(1) not null
		  , FreeSpace VARCHAR(10) not null
		   )

	INSERT INTO #DriveSpace
	EXEC master.dbo.xp_fixeddrives

	IF EXISTS (SELECT TOP 1 1 FROM #DriveSpace WHERE DriveLetter = 'D')
	AND NOT EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Low DATA Disk Space Notification')		
		BEGIN
			EXEC msdb.dbo.sp_add_alert @name=N'Low DATA Disk Space Notification', 
					@message_id=0, 
					@severity=0, 
					@enabled=1, 
					@delay_between_responses=10800, 
					@include_event_description_in=1, 
					@category_name=N'[Uncategorized]', 
					@wmi_namespace=N'\\.\root\CIMV2', 
					@wmi_query=N'SELECT * FROM __instancemodificationevent within 3600 WHERE targetinstance isa ''CIM_LogicalDisk'' and targetinstance.freespace < 3221225472 and targetinstance.name=''D:''', 
					@job_id=N'00000000-0000-0000-0000-000000000000'

			EXEC msdb.dbo.sp_add_notification 
				@alert_name = N'Low DATA Disk Space Notification',
				@operator_name = N'DBA', 
				@notification_method = 1
		END
	IF EXISTS (SELECT TOP 1 1 FROM #DriveSpace WHERE DriveLetter = 'F')
	AND NOT EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Low BACKUP Disk Space Notification')		
		BEGIN
			EXEC msdb.dbo.sp_add_alert @name=N'Low BACKUP Disk Space Notification', 
					@message_id=0, 
					@severity=0, 
					@enabled=1, 
					@delay_between_responses=10800, 
					@include_event_description_in=1, 
					@category_name=N'[Uncategorized]', 
					@wmi_namespace=N'\\.\root\CIMV2', 
					@wmi_query=N'SELECT * FROM __instancemodificationevent within 3600 WHERE targetinstance isa ''CIM_LogicalDisk'' and targetinstance.freespace < 3221225472 and targetinstance.name=''F:''', 
					@job_id=N'00000000-0000-0000-0000-000000000000'

			EXEC msdb.dbo.sp_add_notification 
				@alert_name = N'Low BACKUP Disk Space Notification',
				@operator_name = N'DBA', 
				@notification_method = 1
		END
	IF EXISTS (SELECT TOP 1 1 FROM #DriveSpace WHERE DriveLetter = 'L')
	AND NOT EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Low LOG Disk Space Notification')		
		BEGIN
			EXEC msdb.dbo.sp_add_alert @name=N'Low LOG Disk Space Notification', 
					@message_id=0, 
					@severity=0, 
					@enabled=1, 
					@delay_between_responses=10800, 
					@include_event_description_in=1, 
					@category_name=N'[Uncategorized]', 
					@wmi_namespace=N'\\.\root\CIMV2', 
					@wmi_query=N'SELECT * FROM __instancemodificationevent within 3600 WHERE targetinstance isa ''CIM_LogicalDisk'' and targetinstance.freespace < 3221225472 and targetinstance.name=''L:''', 
					@job_id=N'00000000-0000-0000-0000-000000000000'

			EXEC msdb.dbo.sp_add_notification 
				@alert_name = N'Low LOG Disk Space Notification',
				@operator_name = @Operator, 
				@notification_method = 1
		END
	IF EXISTS (SELECT TOP 1 1 FROM #DriveSpace WHERE DriveLetter = 'U')
	AND NOT EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Low AUDIT Disk Space Notification')		
		BEGIN
			EXEC msdb.dbo.sp_add_alert @name=N'Low AUDIT Disk Space Notification', 
					@message_id=0, 
					@severity=0, 
					@enabled=1, 
					@delay_between_responses=10800, 
					@include_event_description_in=1, 
					@category_name=N'[Uncategorized]', 
					@wmi_namespace=N'\\.\root\CIMV2', 
					@wmi_query=N'SELECT * FROM __instancemodificationevent within 3600 WHERE targetinstance isa ''CIM_LogicalDisk'' and targetinstance.freespace < 3221225472 and targetinstance.name=''U:''', 
					@job_id=N'00000000-0000-0000-0000-000000000000'

			EXEC msdb.dbo.sp_add_notification 
				@alert_name = N'Low AUDIT Disk Space Notification',
				@operator_name =@Operator, 
				@notification_method = 1

		END


	--New Alerts 23/10/2013
	DECLARE @AlertName sysname 

	
	SET @AlertName = N'Severity 019';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
		@message_id=0,
		@severity=19,
		@enabled=1,
		@delay_between_responses=60,
		@include_event_description_in=1,
		@job_id=N'00000000-0000-0000-0000-000000000000';
	
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	SET @AlertName = N'Severity 020';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
		@message_id=0,
		@severity=20,
		@enabled=1,
		@delay_between_responses=60,
		@include_event_description_in=1,
		@job_id=N'00000000-0000-0000-0000-000000000000';
	
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END
	IF EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName AND enabled = 1)
	BEGIN
		EXEC msdb.dbo.sp_update_alert
			 @name = @AlertName,
			 @enabled = 0 ;
	END

	SET @AlertName = N'Severity 021';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
		@message_id=0,
		@severity=21,
		@enabled=1,
		@delay_between_responses=60,
		@include_event_description_in=1,
		@job_id=N'00000000-0000-0000-0000-000000000000';
	
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	SET @AlertName = N'Severity 022';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
		@message_id=0,
		@severity=22,
		@enabled=1,
		@delay_between_responses=60,
		@include_event_description_in=1,
		@job_id=N'00000000-0000-0000-0000-000000000000';
	
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	SET @AlertName = N'Severity 023';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
		@message_id=0,
		@severity=23,
		@enabled=1,
		@delay_between_responses=60,
		@include_event_description_in=1,
		@job_id=N'00000000-0000-0000-0000-000000000000';
	
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	SET @AlertName = N'Severity 024';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
		@message_id=0,
		@severity=24,
		@enabled=1,
		@delay_between_responses=60,
		@include_event_description_in=1,
		@job_id=N'00000000-0000-0000-0000-000000000000';
	
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	SET @AlertName = N'Severity 025';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
		@message_id=0,
		@severity=25,
		@enabled=1,
		@delay_between_responses=60,
		@include_event_description_in=1,
		@job_id=N'00000000-0000-0000-0000-000000000000';
	
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	SET @AlertName = N'Error Number 823';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
		@message_id=823,
			@severity=0,
			@enabled=1,
			@delay_between_responses=60,
			@include_event_description_in=1,
			@job_id=N'00000000-0000-0000-0000-000000000000'
		
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	SET @AlertName = N'Error Number 824';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
			@message_id=824,
			@severity=0,
			@enabled=1,
			@delay_between_responses=60,
			@include_event_description_in=1,
			@job_id=N'00000000-0000-0000-0000-000000000000'
		
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	SET @AlertName = N'Error Number 825';
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysalerts WHERE name = @AlertName)
	BEGIN

		EXEC msdb.dbo.sp_add_alert @name=@AlertName,
			@message_id=825,
			@severity=0,
			@enabled=1,
			@delay_between_responses=60,
			@include_event_description_in=1,
			@job_id=N'00000000-0000-0000-0000-000000000000'
		
		EXEC msdb.dbo.sp_add_notification @alert_name=@AlertName, @operator_name=@Operator, @notification_method = 1;
	END

	


	------------------------------------------------------
	--  create jobs                                     --
	------------------------------------------------------
	
	DECLARE @jobId BINARY(16),
			@job_id UNIQUEIDENTIFIER, 
			@ReturnCode INT = 0

	
	SELECT @job_id = job_id FROM msdb.dbo.sysjobs_view WHERE name = N'_Admin_ :: CycleErrorLog'
	IF NOT @job_id IS null
		EXEC msdb.dbo.sp_delete_job @job_id = @job_id, @delete_unused_schedule = 1
	SET @job_id = NULL;
	-- add category
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE  name = @Operator AND category_class = 1) 
		BEGIN
			EXEC msdb.dbo.sp_add_category @class = N'JOB',@type = N'LOCAL',@name = @Operator
		END

	
---------------------------------------------------------------------------------------------------------------------

	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysjobs WHERE name = '_Admin_ :: CycleErrorLog')
	BEGIN
		SET @jobId = null
		EXEC  msdb.dbo.sp_add_job 
				@job_name=N'_Admin_ :: CycleErrorLog', 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=0, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description=N'sp_cycle_errorlog.', 
				@category_name=@Operator, 
				@owner_login_name=N'sa', 
				@job_id = @jobId OUTPUT

		EXEC msdb.dbo.sp_add_jobstep 
				@job_id=@jobId, 
				@step_name=N'CycleErrorLog', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'EXEC sp_cycle_errorlog;', 
				@database_name=N'master', 
				@flags=0

		EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

		EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'MidNight', 
				@enabled=1, 
				@freq_type=4, 
				@freq_interval=1, 
				@freq_subday_type=1, 
				@freq_subday_interval=0, 
				@freq_relative_interval=0, 
				@freq_recurrence_factor=0, 
				@active_start_date=20140331, 
				@active_end_date=99991231, 
				@active_start_time=1, 
				@active_end_time=235959, 
				@schedule_uid=N'994a993a-227f-463f-9742-f2cba8623403'

		BEGIN TRY 
			EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = @@servername
		END TRY
		BEGIN CATCH
		END CATCH
	END
---------------------------------------------------------------------------------------------------------------------
	IF NOT EXISTS(SELECT TOP 1 1 FROM msdb.dbo.sysjobs WHERE name = '_Admin_ :: GetActiveJobLongRun')
	BEGIN
		SET @jobId = null
		-- _Admin_ :: Data Integrity :: ExecAll
		EXEC  msdb.dbo.sp_add_job @job_name=N'_Admin_ :: GetActiveJobLongRun', 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=2, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description=N'Run all Data Integrity SPs', 
				@category_name=@Operator, 
				@owner_login_name=N'sa', 
				@notify_email_operator_name=@Operator, @job_id = @jobId OUTPUT

		EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'GetActiveJobLongRun', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'DECLARE @SendMail int = 1
EXECUTE  [Report].[usp_General_GetActiveJobLongRun] @SendMail', 
				@database_name=N'_Admin', 
				@flags=0

		EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

		
		EXEC msdb.dbo.sp_add_jobschedule @job_id = @jobId, @name=N'EveryMorning', 
				@enabled=1, 
				@freq_type=4, 
				@freq_interval=1, 
				@freq_subday_type=1, 
				@freq_subday_interval=0, 
				@freq_relative_interval=0, 
				@freq_recurrence_factor=1, 
				@active_start_date=20150308, 
				@active_end_date=99991231, 
				@active_start_time=70000, 
				@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
		BEGIN TRY 
			EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = @@servername
		END TRY
		BEGIN CATCH
		END CATCH
	END
---------------------------------------------------------------------------------------------------------------------
	RETURN 1;
END