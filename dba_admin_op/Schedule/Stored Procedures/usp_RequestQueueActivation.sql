-- =============================================
-- Author:      Sharon
-- Create date: 04/05/2017
-- Update date: 
-- Description: Create procedure for processing replies to the request queue
-- =============================================
CREATE PROCEDURE [Schedule].usp_RequestQueueActivation
AS
BEGIN
  SET NOCOUNT ON;
 
  DECLARE @conversation_handle UNIQUEIDENTIFIER;
  DECLARE @message_body XML;
  DECLARE @message_type_name sysname;
 
  WHILE (1=1)
  BEGIN
 
    WAITFOR
    (
      RECEIVE TOP (1)
        @conversation_handle = conversation_handle,
        @message_body = CAST(message_body AS XML),
        @message_type_name = message_type_name
      FROM JobRequestQueue
    ), TIMEOUT 5000;
 
    IF (@@ROWCOUNT = 0)
    BEGIN
      BREAK;
    END
 
    IF @message_type_name = N'JobRequest'
    BEGIN
      -- If necessary handle the reply message here
      DECLARE @JobNumber INT = @message_body.value('(JobRequest/JobNumber)[1]', 'INT');
      -- Build reply message and send back
      END CONVERSATION @conversation_handle;
	  IF @JobNumber IS NOT NULL EXEC [Schedule].[usp_ScheduleTask_RunJob] @JobNumber;
      -- Since this is all the work being done, end the conversation to send the EndDialog message
      END CONVERSATION @conversation_handle;
    END
 
    -- If end dialog message, end the dialog
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
       END CONVERSATION @conversation_handle;
    END
 
    -- If error message, log and end conversation
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
    BEGIN
       END CONVERSATION @conversation_handle;
    END
 
  END
END