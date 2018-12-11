-- =============================================
-- Author:		Sharon Rimer
-- Create date: 28/09/2014
-- Update date: 29/10/2015 Sharon fix ufn of mail
--				29/11/2015 Sharon Fix Joins
--				13/12/2015 Sharon Conc
-- Description:	
-- =============================================
CREATE PROCEDURE [Report].[usp_GetLongRunningTranInfo]
AS 
BEGIN	
    SET NOCOUNT ON;
	
	DECLARE @MailRecipiants NVARCHAR (255);
	SELECT	@MailRecipiants = [Report].[ufn_Mail_GetMailRecipiantByProcedureName]('DBA');
	DECLARE @MailSubject NVARCHAR (255) = N'Long Running Tran';
	DECLARE @MailProfile sysname = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
	DECLARE @MailBodey NVARCHAR (max) = N'';

	DECLARE @MailTable NVARCHAR (max) = N'';
	DECLARE @LongRunningQ TABLE ([Session ID] INT NULL,
		[Database Name] sysname NULL,
		[command] NVARCHAR(max) NULL,
		statement_text NVARCHAR(max) NULL,
		command_text NVARCHAR(max) NULL,
		wait_type nVARCHAR(60) NULL,
		wait_time INT NULL,
		[MB used] FLOAT,
		[MB used system] FLOAT NULL,
		[MB reserved] FLOAT NULL,
		[MB reserved system] FLOAT NULL,
		[Record count] int NULL
		)
	INSERT @LongRunningQ
	SELECT b.session_id 'Session ID',
		   CAST(Db_name(a.database_id) AS VARCHAR(20)) 'Database Name',
		   c.command,
		   Substring(st.TEXT, ( c.statement_start_offset / 2 ) + 1,
		   ( (
		   CASE c.statement_end_offset
			WHEN -1 THEN Datalength(st.TEXT)
			ELSE c.statement_end_offset
		   END 
		   -
		   c.statement_start_offset ) / 2 ) + 1)                                                             
		   statement_text,
		   Coalesce(Quotename(Db_name(st.dbid)) + N'.' + Quotename(
		   Object_schema_name(st.objectid,
					st.dbid)) +
					N'.' + Quotename(Object_name(st.objectid, st.dbid)), '')    
		   command_text,
		   c.wait_type,
		   c.wait_time,
		   a.database_transaction_log_bytes_used / 1024.0 / 1024.0                 'MB used',
		   a.database_transaction_log_bytes_used_system / 1024.0 / 1024.0          'MB used system',
		   a.database_transaction_log_bytes_reserved / 1024.0 / 1024.0             'MB reserved',
		   a.database_transaction_log_bytes_reserved_system / 1024.0 / 1024.0      'MB reserved system',
		   a.database_transaction_log_record_count                           
		   'Record count'
	FROM   sys.dm_tran_database_transactions a
		   INNER JOIN sys.dm_tran_session_transactions b ON a.transaction_id = b.transaction_id
		   INNER JOIN sys.dm_exec_requests c ON c.database_id = a.database_id
			AND c.session_id = b.session_id
			AND c.transaction_id = a.transaction_id
		   CROSS APPLY sys.Dm_exec_sql_text(c.sql_handle) AS st 
	WHERE	a.database_id > 4
	
	ORDER  BY 'MB used' DESC;

	IF EXISTS (SELECT TOP 1 1 FROM @LongRunningQ)
	BEGIN
		

		SET @MailTable = '<table class="sample">
<tr>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Session ID</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Database Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Command</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Statement Text</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Command Text</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Wait Type</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">MB used</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">MB used system</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">MB reserved</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">MB reserved system</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Record count</td>
</tr>';

    SELECT  @MailTable += CONCAT('<tr><td>',CONVERT(VARCHAR(50),[Session ID])
			, '</td><td>' , [Database Name] 
			, '</td><td>' , [command]
            , '</td><td>' , statement_text 
			, '</td><td>' , command_text
			, '</td><td>' , dbo.ufn_Util_clr_Conc(wait_type + '(' + CONVERT(VARCHAR(50),wait_time) + ')
')
            , '</td><td>' , CONVERT(VARCHAR(50),SUM([MB used]))
			, '</td><td>' , CONVERT(VARCHAR(50),SUM([MB used system]))
			, '</td><td>' , CONVERT(VARCHAR(50),SUM([MB reserved]))
			, '</td><td>' , CONVERT(VARCHAR(50),SUM([MB reserved system]))
			, '</td><td>' , CONVERT(VARCHAR(50),SUM([Record count]))
			, '</td></tr>')
    FROM    @LongRunningQ
	GROUP BY [Session ID],[Database Name] ,[command],statement_text,command_text;

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
			@body_format = HTML;

	END
END