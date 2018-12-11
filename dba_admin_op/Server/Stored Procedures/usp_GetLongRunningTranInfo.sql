-- =============================================
-- Author:		Sharon Rimer
-- Create date: 28/09/2014
-- Update date: 29/10/2015 Sharon fix ufn of mail
--				29/11/2015 Sharon Fix Joins
--				13/12/2015 Sharon Conc
-- Description:	
-- =============================================
CREATE PROCEDURE [Server].[usp_GetLongRunningTranInfo]
AS 
BEGIN	
    SET NOCOUNT ON;

	SELECT GETDATE() [DateTaken],b.session_id 'Session ID',
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
END