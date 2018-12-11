-- =============================================
-- Author:		Sharon Rimer
-- Create date: 03/03/2015
-- Update date: 08/03/2015 Send Mail
--				04/06/2015 Sharon add BI
--				10/11/2015 Sharon Not Replications
-- Description:	Find Active Job Long Run
-- =============================================
CREATE PROCEDURE [Report].[usp_General_GetActiveJobLongRun] (@SendMail INT = 0)
AS 
BEGIN	
	SET NOCOUNT ON ;
	DECLARE @RC INT = 0;
	SELECT  j.name AS JobName ,
			ja.Start_execution_date StartExecutionDate,
			ISNULL(last_executed_step_id, 0) + 1 AS CurrentExecutedStepID ,
			js.step_name StepName,
			CONCAT(joa.Duration,' Min') Duration
	INTO	#ActiveJobs
	FROM    msdb.dbo.sysjobactivity ja
			LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
			INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
			INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id
											AND ISNULL(ja.last_executed_step_id, 0)
											+ 1 = js.step_id
			OUTER APPLY ( SELECT  DATEDIFF(MINUTE,ja.start_execution_date,GETDATE()) Duration ) joa
	WHERE   ja.session_id = ( SELECT TOP 1
										session_id
							  FROM      msdb.dbo.syssessions
							  ORDER BY  agent_start_date DESC
							)
			AND start_execution_date IS NOT NULL
			AND stop_execution_date IS NULL
			AND joa.Duration > 30
			AND J.name NOT IN ('_Admin_ :: TrackBlocking')
			AND J.name NOT LIKE 'collection_set%'
			AND J.name NOT LIKE 'sysutility_get%'
			AND j.category_id NOT BETWEEN 10 AND 20;
	SET @RC = @@ROWCOUNT;
	IF @SendMail = 0 
	BEGIN
		SELECT	*
		FROM	#ActiveJobs
	END
	ELSE IF @RC > 0 AND @SendMail = 1
	BEGIN
		--SELECT	* 
		--FROM	MSDB.dbo.sysoperators
		--WHERE	name = 'BI'

		DECLARE @MailRecipiants NVARCHAR (255);
		DECLARE @copy_recipients NVARCHAR (255);
		SELECT	@MailRecipiants = [Report].[ufn_Mail_GetMailRecipiantByProcedureName](NULL),
				@copy_recipients = [Report].[ufn_Mail_GetMailRecipiantByProcedureName]('BI');
		IF EXISTS (SELECT TOP 1 1 FROM MSDB.dbo.sysoperators WHERE	name = 'BI')
			SELECT	@MailRecipiants += [Report].[ufn_Mail_GetMailRecipiantByProcedureName]('BI');
		DECLARE @MailSubject NVARCHAR (255) = N'';
		DECLARE @MailProfile sysname = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
		DECLARE @MailBodey NVARCHAR (max) = N'';

		DECLARE @MailTable NVARCHAR (max) = N'';

		SET @MailSubject = N'Active Job Long & still Running on: ' + @@SERVERNAME +' | ' + convert (nvarchar (50), GETDATE(), 100) ;
		SET @MailTable = '<table class="sample">
<tr>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Job Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Start Execution Date</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Current Executed Step ID</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Step Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Duration</td>
</tr>';

    SELECT  @MailTable += '<tr><td>' + JobName 
			+ '</td><td>' + CONVERT(NVARCHAR(25),StartExecutionDate) 
			+ '</td><td>' + CONVERT(NVARCHAR(25),CurrentExecutedStepID)
            + '</td><td>' + StepName 
			+ '</td><td>' + Duration
			+ '</td></tr>'
    FROM    #ActiveJobs;

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
			@copy_recipients = @copy_recipients,
			@subject = @MailSubject,
			@body = @MailBodey,
			@body_format = HTML,
			@exclude_query_output = 1;

	IF OBJECT_ID('tempdb..#ActiveJobs') IS NOT NULL DROP TABLE #ActiveJobs

	END
END