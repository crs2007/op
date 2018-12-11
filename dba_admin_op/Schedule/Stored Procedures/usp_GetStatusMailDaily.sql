-- =============================================
-- Author:      Sharon
-- Create date: 04/05/2017
-- Update date: 
-- Description: Create processing procedure for processing queue
-- =============================================
CREATE PROCEDURE [Schedule].[usp_GetStatusMailDaily]
AS
BEGIN
  SET NOCOUNT ON;
		DECLARE @MailRecipiants NVARCHAR (255);
		DECLARE @copy_recipients NVARCHAR (255);
		SELECT	@copy_recipients = 'Sharonri@openu.ac.il';
		DECLARE @MailSubject NVARCHAR (255) = N'';
		DECLARE @MailProfile sysname = (SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);
		DECLARE @MailBodey NVARCHAR (max) = N'';

		DECLARE @MailTable NVARCHAR (max) = N'';

		SET @MailSubject = N'Faild Jobs over night: ' + @@SERVERNAME +' | ' + convert (nvarchar (50), GETDATE(), 100) ;
		SET @MailTable = '<table class="sample">
<tr>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Server Name</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Database</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Code</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Task Status</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">How many times</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Execution Date</td>
	<td style="background-color:#E6E6E6; color:#2E64FE; font-weight:bolder;font-size:14px;">Error</td>td>
</tr>';


/* declare variables */
DECLARE @Database sysname;
DECLARE @Code NVARCHAR(MAX);
DECLARE @Status sysname;
DECLARE @NOTimes INT;
DECLARE @Date DATETIME;
DECLARE @Error NVARCHAR(MAX);

DECLARE cuJobMailStatus CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
SELECT	c.[Database],c.StoredProcedure,l.TaskStatus,COUNT_BIG(1) [HowManyTimesTheJobHaveRun],MAX(l.StartDate) [At],l.AdditionalInformation [Error],REPLACE(dbo.ufn_Util_clr_Conc(DISTINCT ML.Mail),',',';') + ';'
FROM	Schedule.Log_ScheduleTaskLog l
		INNER JOIN Schedule.Schedule_Configuration c ON c.ID = l.ScheduleTaskID
		INNER JOIN Schedule.Schedule_cl_ConfigurationMailListScheduleTask CL ON CL.ScheduleTaskID = c.ID
		INNER JOIN  Schedule.Schedule_ConfigurationMailList ML ON CL.MailID = ML.ID
WHERE	ISNULL(c.Server,@@SERVERNAME) = @@SERVERNAME
		AND l.StartDate BETWEEN DATEADD(DAY, DATEDIFF(DAY, '19000101', DATEADD(DAY,-1,GETDATE())), '19000101') AND DATEADD(DAY, DATEDIFF(DAY, '19000101', DATEADD(DAY,-1,GETDATE())), '23:59:59')
		AND TaskStatus = N'Failed'
GROUP BY c.[Database],c.StoredProcedure,l.TaskStatus,l.AdditionalInformation

OPEN cuJobMailStatus

FETCH NEXT FROM cuJobMailStatus INTO @Database,@Code,@Status,@NOTimes,@Date,@Error,@MailRecipiants;

WHILE @@FETCH_STATUS = 0
BEGIN
    

    SELECT  @MailTable += CONCAT('<tr><td>' , @@SERVERNAME
			, '</td><td>' , @Database 
			, '</td><td>' , @Code
            , '</td><td>' , @Status
			, '</td><td>' , @NOTimes
			, '</td><td>' , @Date
            , '</td><td>' , @Error
			, '</td></tr>');

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


			
    FETCH NEXT FROM cuJobMailStatus INTO @Database,@Code,@Status,@NOTimes,@Date,@Error,@MailRecipiants;
END

CLOSE cuJobMailStatus;
DEALLOCATE cuJobMailStatus;

END