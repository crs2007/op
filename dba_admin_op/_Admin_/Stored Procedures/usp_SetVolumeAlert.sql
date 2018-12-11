-- =============================================
-- Author:		Sharon
-- Create date: 17/02/2016
-- Update date: 02/03/2016
-- Description:	Set Alert on server
-- =============================================
CREATE PROCEDURE [_Admin_].[usp_SetVolumeAlert] 
    @Operator sysname = NULL
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @serverName VARCHAR(500);
	DECLARE @sql VARCHAR(400);
	DECLARE @cmd NVARCHAR(MAX) = N'';
	DECLARE @cmdNotification NVARCHAR(MAX) = N'';
	IF @Operator IS NULL
		SELECT	TOP 1 @Operator = S.name
		FROM	msdb..sysoperators S
		WHERE	S.name LIKE '%DBA%' OR S.name LIKE '%Admin%'
	SET @serverName = @@ServerName;
	SET @sql = 'powershell.exe -c "Get-WmiObject -ComputerName '
		+ QUOTENAME(@serverName, '''')
		+ ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"';
	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result
	CREATE TABLE #Result ( list VARCHAR(255) );
	INSERT  #Result
			EXEC xp_cmdshell @sql;

	SELECT C.DriveName ,
	        C.[Capacity(GB)] ,
			b.[Byte],
			b.[MB],
			b.[GB],
			ISNULL(D.LastSample,0)LastSample,
	        C.[Freespace(GB)],'
IF EXISTS(SELECT TOP 1 1 FROM msdb..sysalerts S WHERE name=N''' + D.Description + ''')
	EXEC msdb.dbo.sp_delete_alert @name=N''' + D.Description + '''
EXEC msdb.dbo.sp_add_alert @name=N''' + D.Description + ''', 
	@message_id=0, 
	@severity=0, 
	@enabled=1, 
	@delay_between_responses=10800, 
	@include_event_description_in=1, 
	@category_name=N''[Uncategorized]'', 
	@wmi_namespace=N''\\.\root\CIMV2'', 
	@wmi_query=N''SELECT * FROM __instancemodificationevent within 3600 WHERE targetinstance isa ''''CIM_LogicalDisk'''' and targetinstance.freespace < ' + CONVERT(VARCHAR(50),b.[Byte]) + ' and targetinstance.name=''''' + C.DriveAlert + ''''''', 
	@job_id=N''00000000-0000-0000-0000-000000000000'';'[Script],
'
EXEC msdb.dbo.sp_add_notification @alert_name=N''' + D.Description + ''', @operator_name=N''' + @Operator +  ''', @notification_method = 1;
'[notification]
	INTO	#Action
	FROM    #Result
			CROSS APPLY (SELECT RTRIM(LTRIM(SUBSTRING(list, 1, CHARINDEX('|', list) - 1))) AS DriveName,RTRIM(LTRIM(SUBSTRING(list, 1, CHARINDEX('|', list) - 2))) AS DriveAlert,
			ROUND(CAST(RTRIM(LTRIM(SUBSTRING(list, CHARINDEX('|', list) + 1,
											 ( CHARINDEX('%', list) - 1 )
											 - CHARINDEX('|', list)))) AS FLOAT)
				  / 1024, 0) AS [Capacity(GB)],
				ROUND(CAST(RTRIM(LTRIM(SUBSTRING(list, CHARINDEX('%', list) + 1,
	                                         ( CHARINDEX('*', list) - 1 )
	                                         - CHARINDEX('%', list)))) AS FLOAT)
	              / 1024, 0) AS [Freespace(GB)])c
			INNER JOIN [_Admin_].[DriveAlert] d ON C.DriveName = D.DriveName
			CROSS APPLY (SELECT CONVERT(BIGINT,[Capacity(GB)]*(D.[Percent]/100.0)*(POWER(1024,3))) [Byte],
								CONVERT(INT,[Capacity(GB)]*(D.[Percent]/100.0)*(POWER(1024,2)))[MB],
								CONVERT(INT,[Capacity(GB)]*(D.[Percent]/100.0))[GB])b
	WHERE   list LIKE '[A-Z][:]%'
	ORDER BY drivename;

	SELECT	@cmd += A.Script,
			@cmdNotification += [notification]
	FROM	#Action A
	WHERE	A.MB != A.LastSample
	
	EXEC sp_executesql @cmd;
	EXEC sp_executesql @cmdNotification;

	UPDATE D
	SET		LastSample = A.MB
	FROM	[_Admin_].[DriveAlert] D
			INNER JOIN #Action A ON A.DriveName = D.DriveName
	WHERE	A.MB != D.LastSample;

END