-- =============================================
-- Author:      Sharon
-- Create date: 2017
-- Update date: 
-- Description: Run on time
-- =============================================
CREATE PROCEDURE [Schedule].[usp_ScheduleTask_RunJob] @JobID INT = NULL
AS 
BEGIN  
    SET NOCOUNT ON;

    DECLARE @cmd NVARCHAR(MAX) = '';
    DECLARE @now TIME = CONVERT(TIME,GETDATE());

    SELECT  @cmd += N'

BEGIN TRY  
       SELECT @StartDate = GETDATE(); 

       EXEC ' + QUOTENAME(ES.[Database]) + N'.' + ES.[StoredProcedure] + N';
       SET @RC = @@ROWCOUNT;
       SELECT @EndDate = GETDATE();

       INSERT [Schedule].[Log_ScheduleTaskLog]
       (ScheduleTaskID, TaskStatus, StartDate, EndDate, EffectedRows, AdditionalInformation)
       VALUES (' + CONVERT(NVARCHAR(10),ES.ID) + N',''successfully'',@StartDate,@EndDate,@RC,NULL)
              
END TRY
BEGIN CATCH
       SELECT @EndDate = GETDATE();
       SELECT @err = ERROR_MESSAGE();
       INSERT [Schedule].[Log_ScheduleTaskLog] 
       (ScheduleTaskID, TaskStatus, StartDate, EndDate, EffectedRows, AdditionalInformation)
       VALUES (' + CONVERT(NVARCHAR(10),ES.ID) + N',''Failed'',@StartDate,GETDATE(),NULL,@err)

END CATCH
'
    FROM    [Schedule].[Schedule_Configuration]ES
            INNER JOIN sys.databases D WITH(NOLOCK) ON D.name = ES.[Database]
    WHERE   @JobID = ES.ID
            AND ES.IsActive = 1
            AND D.[state] = 0;

       
    SET @cmd = N'
DECLARE @RC INT = 0,
              @err NVARCHAR(2048) = '''',
              @StartDate DATETIME ,
              @EndDate DATETIME;
' + @cmd;
    EXEC sys.sp_executesql @cmd;
END