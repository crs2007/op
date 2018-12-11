-- =============================================
-- Author:		Sharon Rimer
-- Create date: 1/11/2016
-- Description:	Find Who Lock DB
-- =============================================
CREATE PROCEDURE [dbo].[usp_WhoIsLocking] @LockInMinuts SMALLINT = 10
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @s VARCHAR(MAX)
	----DROP TABLE tempdb.dbo.WhoIsActive;

	IF OBJECT_ID('tempdb.dbo.WhoIsActive') IS NOT NULL
	BEGIN
		DROP TABLE tempdb.dbo.WhoIsActive;
	END
	EXEC [_Admin].dbo.sp_WhoIsActive 
    @find_block_leaders = 1, 
	@output_column_list= '[dd hh:mm:ss.mss],[session_id],[sql_text],[sql_command],[login_name],[wait_info],[tran_log_writes],[CPU],[tempdb_allocations],[tempdb_current],[blocking_session_id],[blocked_session_count],[reads],[writes],[physical_reads],[locks],[used_memory],[status],[tran_start_time],[open_tran_count],[percent_complete],[host_name],[database_name],[program_name],[additional_info],[start_time],[login_time],[request_id],[collection_time]',
    @sort_order = '[blocked_session_count] DESC',
    @format_output = 1, 
    @return_schema = 1, 
    @schema = @s OUTPUT

	SET @s = REPLACE(@s, '<table_name>', 'tempdb.dbo.WhoIsActive')

	EXEC(@s);  

	--TRUNCATE TABLE tempdb.dbo.WhoIsActive;
	BEGIN TRY
	EXEC [_Admin].dbo.sp_WhoIsActive 
		@find_block_leaders = 1, 
		@sort_order = '[blocked_session_count] DESC',
		@format_output = 1, 
		@destination_table = 'tempdb.dbo.WhoIsActive'
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
		RETURN;
	END CATCH

	DECLARE @session_id	 INT;
	DECLARE @kill NVARCHAR(max);
	DECLARE @HTML NVARCHAR(max) = '';
	IF EXISTS (SELECT TOP 1 1 FROM tempdb.dbo.WhoIsActive WHERE blocking_session_id IS NOT NULL AND DATEDIFF(MINUTE,start_time,collection_time) > ISNULL(@LockInMinuts,10))
	BEGIN
		SELECT	TOP 1 
				session_id,login_name,wait_info,[host_name],
				[database_name],
				start_time,
				[dd hh:mm:ss.mss],
				REPLACE(REPLACE(CONVERT(NVARCHAR(max),sql_command),'<?query --',''),'--?>','')[sql_command],
				[Waiting]
		INTO	#Locking
		FROM	tempdb.dbo.WhoIsActive a
				OUTER APPLY(SELECT COUNT(1) [Waiting]FROM tempdb.dbo.WhoIsActive b WHERE b.session_id != a.session_id)ac
		WHERE	blocking_session_id IS NULL AND blocked_session_count > 0 AND DATEDIFF(MINUTE,start_time,collection_time) > ISNULL(@LockInMinuts,10);
		SELECT TOP 1 @session_id = session_id FROM #Locking WHERE [database_name] LIKE 'SP2013[_]PROD[_]SeminarWorks%';
	END

	IF @session_id IS NOT NULL
	BEGIN
	SET @kill = CONCAT('KILL ',@session_id,';');
	PRINT @kill
	EXEC (@kill);

	DECLARE @MailRecipiants NVARCHAR (255);
			DECLARE @copy_recipients NVARCHAR (255);
			SELECT	@MailRecipiants = 'eliza@openu.ac.il;erans@openu.ac.il;zoharbe@openu.ac.il;zohard@openu.ac.il',
					@copy_recipients = 'sharonri@openu.ac.il';
			DECLARE @MailSubject NVARCHAR (255) = N'';
			DECLARE @MailProfile sysname = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
		

			DECLARE @MailTable NVARCHAR (max) = N'';

			SET @MailSubject = N'Blocking Proccess Running on: ' + @@SERVERNAME +' | ' + convert (nvarchar (50), GETDATE(), 100) ;
		
	
	SELECT TOP 1 @HTML = CONCAT('<!DOCTYPE html>
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
<br/>
<br>Server			- ',@@SERVERNAME,'
<br>session_id		- ',session_id,'
<br>login_name		- ',login_name,'
<br>wait_info		- ',wait_info,'
<br>host_name		- ',[host_name],'
<br>database_name	- ',[database_name],'
<br>start_time		- ',start_time,'
<br>Duration		- ',[dd hh:mm:ss.mss],' (dd hh:mm:ss.mss)
<br>What is runinng	- ',sql_command,' 
<br>Waiting	Proccess- ',[Waiting],'<br/>

</font>
</body>
</html>') FROM #Locking

			EXEC msdb.dbo.sp_send_dbmail	
			@profile_name = @MailProfile,
			@recipients = @MailRecipiants,
			@copy_recipients = @copy_recipients,
			@subject = @MailSubject,
			@body = @HTML,
			@body_format = HTML,
			@exclude_query_output = 1;

			
END

TRUNCATE TABLE tempdb.dbo.WhoIsActive;
END