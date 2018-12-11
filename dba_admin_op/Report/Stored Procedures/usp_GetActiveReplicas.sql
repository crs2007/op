-- =============================================
-- Author:		Sharon Rimer
-- Create date: 28/09/2014
-- Update date: 29/10/2015 Sharon fix ufn of mail
--				29/11/2015 Sharon Fix Joins
--				13/12/2015 Sharon Conc
-- Description:	
-- =============================================
CREATE PROCEDURE [Report].[usp_GetActiveReplicas]
AS 
BEGIN	
    SET NOCOUNT ON;
	
	DECLARE @MailRecipiants NVARCHAR (255);
	SELECT	@MailRecipiants = [Report].[ufn_Mail_GetMailRecipiantByProcedureName]('DBA');
	DECLARE @MailSubject NVARCHAR (255) = N'Additional Active Replicas On Server ' + @@SERVERNAME + ' with BI Replica.';
	DECLARE @MailProfile sysname = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
	DECLARE @MailBodey NVARCHAR (max) = N'';
	
	DECLARE @MailTable NVARCHAR (max) = N'';
	DECLARE @Replica TABLE ([Replica Name] sysname NOT NULL,
		[Databases] NVARCHAR(max) NOT NULL);

	IF EXISTS(SELECT  TOP 1 1 FROM master.sys.availability_groups g
	inner join master.sys.dm_hadr_availability_replica_states r
	on g.group_id = r.group_id
	where g.name = 'BI-DB' 
	and  is_local = 1
	AND r.role = 1) 
	BEGIN
		INSERT @Replica
		select	g.name,dbo.ufn_Util_clr_Conc(dhdrcs.database_name) [DatabaseName]
		fROM	master.sys.availability_groups g
				INNER JOIN master.sys.dm_hadr_availability_replica_states r on g.group_id = r.group_id
				INNER JOIN master.sys.dm_hadr_database_replica_cluster_states dhdrcs ON dhdrcs.replica_id = r.replica_id
		where	g.name != 'BI-DB' 
				and  r.is_local = 1
				AND r.role = 1
		GROUP BY g.name

	IF EXISTS (SELECT TOP 1 1 FROM @Replica)
	BEGIN
		

		SET @MailTable = '<table class="sample">
<tr>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Replica Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Databases</td>
</tr>';

    SELECT  @MailTable += CONCAT('<tr><td>',CONVERT(VARCHAR(50),[Replica Name])
			, '</td><td>' , [Databases] 
			, '</td></tr>')
    FROM    @Replica;

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

	END
	END
END