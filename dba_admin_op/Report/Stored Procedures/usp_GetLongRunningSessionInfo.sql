-- =============================================
-- Author:		Sharon Rimer
-- Create date: 28/09/2014
-- Update date: 29/10/2015 Sharon fix ufn of mail
--				06/12/2015 Sharon Add Columns
--				21/12/2015 Sharon 91875
--				22/12/2015 Sharon [IsKillSessionAllow]
-- Description:	
-- =============================================
CREATE PROCEDURE [Report].[usp_GetLongRunningSessionInfo]
AS 
BEGIN	
    SET NOCOUNT ON;
	DECLARE @HostName NVARCHAR(128)
	DECLARE @OnlyApp BIT = 1
	DECLARE @DatabaseName sysname 
	DECLARE @Mode INT
	DECLARE @TimeOn BIT = 1
	DECLARE @JobInfoOn BIT = 0
	DECLARE @OnlyRunnigProcessOn BIT = 0
	DECLARE @TimeFilter BIT = 1
	DECLARE @IncludeSystemDatabase BIT = 0
	DECLARE @IncludeAllUserDatabase BIT = 1
	DECLARE @ConsiderIgnorList BIT = 1
	DECLARE @FilterJob BIT = 1
	
	DECLARE @MailRecipiants NVARCHAR (255);
	SELECT	@MailRecipiants = [Report].[ufn_Mail_GetMailRecipiantByProcedureName]('DBA');
	DECLARE @MailSubject NVARCHAR (255) = N'Long Running Session Info';
	DECLARE @MailProfile sysname = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
	DECLARE @MailBodey NVARCHAR (max) = N'';
	DECLARE @IsKill BIT = 0;
	DECLARE @MailTable NVARCHAR (max) = N'';
	DECLARE @LongRunningQ TABLE (
		[dd hh:mm:ss.mss] VARCHAR(15),
		[SessionID] INT NULL,
		[Database Name] sysname NULL,
		[StoredProcedure] VARCHAR(255),
		[HostName] sysname,
		[LoginName] sysname NULL,
		[ProgramName] VARCHAR(255) NULL,
		[ConnectionMethud] sysname NULL,
		[Status] sysname NULL,
		[WaitType] VARCHAR(255) NULL,
		TransactionIsolationLevel NVARCHAR(max) NULL,
		[Command] NVARCHAR(max) NULL,
		CommandText NVARCHAR(max) NULL,
		KillThatMotherFuker NVARCHAR(25) NULL
		);


	INSERT @LongRunningQ
	EXECUTE [_Admin_].[usp_GetSessionInfo] 
			   @HostName
			  ,@OnlyApp
			  ,@DatabaseName
			  ,@Mode
			  ,@TimeOn
			  ,@JobInfoOn
			  ,@OnlyRunnigProcessOn
			  ,@TimeFilter
			  ,@IncludeSystemDatabase
			  ,@IncludeAllUserDatabase
			  ,@ConsiderIgnorList
			  ,@FilterJob

	IF EXISTS (SELECT TOP 1 1 FROM @LongRunningQ)
	BEGIN
		

		SET @MailTable = '<table class="sample">
<tr>
	
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Time</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Session ID</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Stored Procedure</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Host Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Login Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Program Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Connection Methud</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Status</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Wait Type</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Transaction Isolation Level</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Command</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">CommandText</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Database Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Additional Info</td>
</tr>';

    SELECT  @MailTable += CONCAT('<tr><td>' , [dd hh:mm:ss.mss] ,
			'</td><td>',CONVERT(VARCHAR(50),[SessionID])
			, '</td><td>' , StoredProcedure
			, '</td><td>' , [HostName]
			, '</td><td>' , [LoginName]
			, '</td><td>' , [ProgramName]
			, '</td><td>' , [ConnectionMethud]
            , '</td><td>' , [Status]
            , '</td><td>' , WaitType
			, '</td><td>' , TransactionIsolationLevel
			, '</td><td>' , [Command]
			, '</td><td>' , CommandText
			, '</td><td>' , [Database Name] 
			, '</td><td><font color="#FF0000">' , IIF(KillThatMotherFuker != '' AND @IsKill = 1,'Kill Session was activate','')
			, '</font></td></tr>')
    FROM    @LongRunningQ;

    SET @MailTable += '
</table>'

	SET @MailBodey+=
'
<!DOCTYPE html>
<html>
<body>
<style type="text/css">
table.sample {
	font-family:Calibri;
	font-size:small;
	border-width: 1px;
	border-spacing: 0px;
	border-style: solid;
	border-color: gray;
	border-collapse: collapse;
	background-color: white;}
table.sample th {
	border-width: 1px;
	padding: 3px;
	border-style: solid;
	border-color: gray;
	background-color: white;
	}
table.sample td {
	font-family:Calibri;
	font-size:12px;
	border-width: 1px;
	padding: 3px;
	border-style: solid;
	border-color: gray;
	background-color: white;
	}
</style>
<font face="Calibri (Body)">
<H1><p style=''font-size:18.0pt;font-family:"Bradley Hand ITC"''>' + @MailSubject + N'</p></H1>
<br/>' + @MailTable  + '<br/>

</font>
</body>
</html>';

	EXEC msdb.dbo.sp_send_dbmail	
			@profile_name = @MailProfile,
			@recipients = @MailRecipiants,
			@subject = @MailSubject,
			@body = @MailBodey,
			@body_format = HTML,
			@exclude_query_output = 1;
	

	IF @IsKill = 1
	BEGIN
		DECLARE @Kill NVARCHAR(25)
	
		DECLARE cuKill CURSOR FAST_FORWARD READ_ONLY FOR SELECT KillThatMotherFuker FROM @LongRunningQ WHERE KillThatMotherFuker != ''
	
		OPEN cuKill
	
		FETCH NEXT FROM cuKill INTO @Kill
	
		WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN TRY 
				EXEC @Kill;
			END TRY
			BEGIN CATCH
			
				THROW;
			
			END CATCH
			
			FETCH NEXT FROM cuKill INTO @Kill
		END
	
		CLOSE cuKill
		DEALLOCATE cuKill

		END
	END
END