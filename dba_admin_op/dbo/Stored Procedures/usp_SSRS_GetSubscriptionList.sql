-- =============================================
-- Author:		Sharon Rimer
-- Create date: 13/01/2016
-- Description:	Get Sub List
-- =============================================
CREATE PROCEDURE [dbo].[usp_SSRS_GetSubscriptionList]
	@Exec BIT = 0
AS
BEGIN 
	SET NOCOUNT ON;
	DECLARE @ExecSQL NVARCHAR(MAX) = N'';
	DECLARE @state BIT = 0;
	DECLARE @ReportServerDB TABLE (DatabaseName sysname);
	INSERT @ReportServerDB
			EXEC sp_MSforeachdb 'SELECT TOP 1 ''?'' [DatabaseName]
FROM	[?].sys.database_principals DP
WHERE	DP.type = ''R'' AND DP.name = N''RSExecRole''
		AND ''?'' NOT IN (''master'',''msdb'',''ReportServerTempDB'')
		AND ''?'' NOT LIKE ''%TempDB''
OPTION  ( RECOMPILE );';

	DECLARE @DatabaseName sysname;

	DECLARE cuReportServerSSRSSub CURSOR LOCAL FAST_FORWARD READ_ONLY FOR SELECT DatabaseName FROM @ReportServerDB

	OPEN cuReportServerSSRSSub

	FETCH NEXT FROM cuReportServerSSRSSub INTO @DatabaseName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @ExecSQL = N'SELECT  SUB.SubscriptionID,
		USR.UserName AS SubscriptionOwner ,
        SUB.ModifiedDate ,
        SUB.[Description] ,
        SUB.EventType ,
        SUB.DeliveryExtension ,
        SUB.LastStatus ,
        SUB.LastRunTime ,
        SCH.NextRunTime ,
        SCH.Name AS ScheduleName ,
        CAT.[Path] AS ReportPath ,
        CAT.[Description] AS ReportDescription
FROM    ' + QUOTENAME(@DatabaseName) + '.dbo.Subscriptions AS SUB
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.dbo.Users AS USR ON SUB.OwnerID = USR.UserID
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.dbo.[Catalog] AS CAT ON SUB.Report_OID = CAT.ItemID
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.dbo.ReportSchedule AS RS ON SUB.Report_OID = RS.ReportID
                                               AND SUB.SubscriptionID = RS.SubscriptionID
        INNER JOIN ' + QUOTENAME(@DatabaseName) + '.dbo.Schedule AS SCH ON RS.ScheduleID = SCH.ScheduleID
ORDER BY USR.UserName, CAT.[Path];';

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
		FETCH NEXT FROM cuReportServerSSRSSub INTO @DatabaseName;
	END

	CLOSE cuReportServerSSRSSub;
	DEALLOCATE cuReportServerSSRSSub;


END