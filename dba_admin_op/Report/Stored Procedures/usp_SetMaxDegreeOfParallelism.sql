-- =============================================
-- Author:		Sharon Rimer
-- Create date: 28/09/2014
-- Update date: 29/10/2015 Sharon fix ufn of mail
--				29/11/2015 Sharon Fix Joins
--				13/12/2015 Sharon Conc
-- Description:	
-- =============================================
CREATE PROCEDURE [Report].[usp_SetMaxDegreeOfParallelism]
AS 
BEGIN	
    SET NOCOUNT ON;
	
	DECLARE @MailRecipiants NVARCHAR (255);
	SELECT	@MailRecipiants = [Report].[ufn_Mail_GetMailRecipiantByProcedureName]('BI');
	DECLARE @MailSubject NVARCHAR (255) = @@SERVERNAME + N': max degree of parallelism, change back to 0.';
	DECLARE @MailProfile sysname = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
	DECLARE @MailBodey NVARCHAR (max) = N'';
	
	DECLARE @MailTable NVARCHAR (max) = N'';
	DECLARE @Replica TABLE ([Replica Name] sysname NOT NULL,
		[Databases] NVARCHAR(max) NOT NULL);

	IF EXISTS(SELECT  TOP 1 1 FROM sys.configurations WHERE name = 'max degree of parallelism' AND value != 0) 
	BEGIN
		EXEC sp_configure 'max degree of parallelism',0;
		RECONFIGURE WITH OVERRIDE;

		

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
<br/><br/>

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

	END
END