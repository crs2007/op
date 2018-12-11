-- =============================================
-- Author:		Sharon Rimer
-- Create date: 13/01/2016
-- Description:	Restore Backup file to server location
-- =============================================
CREATE PROCEDURE [dbo].[usp_HADR_ReportServerSubscriptionManager]
	@Exec BIT = 0
AS
BEGIN 
	SET NOCOUNT ON;
	DECLARE @ExecSQL NVARCHAR(MAX) = N'';
	DECLARE @state BIT = 0;
	DECLARE @ReportServerDB TABLE (DatabaseName sysname);	
	DECLARE @Jobs TABLE (JobName sysname);
	INSERT @ReportServerDB
			EXEC sp_MSforeachdb 'SELECT TOP 1 ''?'' [DatabaseName]
FROM	[?].sys.database_principals DP
WHERE	DP.type = ''R'' AND DP.name = N''RSExecRole''
		AND ''?'' NOT IN (''master'',''msdb'',''ReportServerTempDB'')
		AND ''?'' NOT LIKE ''%TempDB''
OPTION  ( RECOMPILE );';

	DECLARE @DatabaseName sysname;

	DECLARE cuReportServerJobs CURSOR LOCAL FAST_FORWARD READ_ONLY FOR SELECT DatabaseName FROM @ReportServerDB

	OPEN cuReportServerJobs

	FETCH NEXT FROM cuReportServerJobs INTO @DatabaseName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @state = 0;
		SET @ExecSQL = N'';
		IF EXISTS ( SELECT	TOP 1 1
					FROM    master.sys.availability_groups g
							INNER JOIN master.sys.dm_hadr_availability_replica_states r ON g.group_id = r.group_id
							INNER JOIN master.sys.dm_hadr_database_replica_states rs ON g.group_id = rs.group_id
							INNER JOIN master.sys.databases d ON d.database_id = rs.database_id
					WHERE   d.name = @DatabaseName
							AND rs.is_local = 1
							AND r.role = 1 ) 
			SET @state = 1;



		DELETE FROM @Jobs;
		SET @ExecSQL = N'SELECT  RS.ScheduleID
FROM    ' + QUOTENAME(@DatabaseName) + '.dbo.Subscriptions AS SUB
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.dbo.Users AS USR ON SUB.OwnerID = USR.UserID
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.dbo.[Catalog] AS CAT ON SUB.Report_OID = CAT.ItemID
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.dbo.ReportSchedule AS RS ON SUB.Report_OID = RS.ReportID
                                               AND SUB.SubscriptionID = RS.SubscriptionID
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.dbo.Schedule AS SCH ON RS.ScheduleID = SCH.ScheduleID
ORDER BY USR.UserName, CAT.[Path];';

		IF @Exec = 1
		BEGIN
			INSERT @Jobs
			EXEC master.sys.sp_executesql @ExecSQL;
		END
		ELSE
		BEGIN
			PRINT '---------------------------'
			EXEC [dbo].[PrintMax] @ExecSQL;
			PRINT CONCAT('@state - ',@state);
			PRINT '---------------------------'
			INSERT @Jobs
			EXEC master.sys.sp_executesql @ExecSQL;
		END
		SET @ExecSQL =	N'DECLARE @Print NVARCHAR(4000);
';
		SELECT  @ExecSQL += CONCAT(N'IF NOT EXISTS (SELECT TOP 1 1 FROM msdb.dbo.sysjobs WHERE name = N''',j.name, ''' AND enabled = ',@state,')
BEGIN
		EXEC msdb.dbo.sp_update_job @job_name = N''',j.name,''', @enabled = ',@state,';
		SET @Print = ''Job - ',j.name, ' Has been ' , IIF(@state = 1,'enabled','disabled') , ''';
		PRINT @Print;
END',CHAR(13)) 
		FROM    msdb.dbo.sysjobs AS j
				INNER JOIN msdb.dbo.syscategories AS c ON j.category_id = c.category_id
		WHERE   j.name IN (SELECT JobName FROM @Jobs)
				AND j.enabled = ~@state;
		
  		IF @Exec = 1
		BEGIN
			EXEC master.sys.sp_executesql @ExecSQL;
		END
		ELSE
		BEGIN
			PRINT '---------------------------'
			EXEC [dbo].[PrintMax] @ExecSQL;
			PRINT '---------------------------'
		END
		FETCH NEXT FROM cuReportServerJobs INTO @DatabaseName;
	END

	CLOSE cuReportServerJobs;
	DEALLOCATE cuReportServerJobs;

END