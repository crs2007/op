-- =============================================
-- Author:      Sharon
-- Create date: 04/05/2017
-- Update date: 
-- Description: Create processing procedure for processing queue
-- =============================================
CREATE PROCEDURE [Schedule].usp_ProcessingQueueActivation
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
      FROM JobProcessingQueue
    ), TIMEOUT 5000;
 
    IF (@@ROWCOUNT = 0)
    BEGIN
      BREAK;
    END
 
    IF @message_type_name = N'JobRequest'
    BEGIN
      -- Handle complex long processing here
      -- For demonstration we'll pull the account number and send a reply back only
      DECLARE @JobNumber INT = @message_body.value('(JobRequest/JobNumber)[1]', 'INT');
      -- Build reply message and send back
      END CONVERSATION @conversation_handle;
	  EXEC [Schedule].[usp_ScheduleTask_RunJob] @JobNumber

    END
 
    -- If end dialog message, end the dialog
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
      END CONVERSATION @conversation_handle;
    END
 
    -- If error message, log and end conversation
    ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
    BEGIN
      -- Log the error code and perform any required handling here
      -- End the conversation for the error
      END CONVERSATION @conversation_handle;
    END
 
  END
END