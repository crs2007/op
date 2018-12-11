-- =============================================
-- Author:      Sharon
-- Create date: 04/05/2017
-- Update date: 
-- Description: Create the wrapper procedure for sending messages
-- =============================================
CREATE PROCEDURE [Schedule].usp_SendBrokerMessage 
	@MessageBody XML
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @FromService SYSNAME = 'JobRequestService',
			@ToService   SYSNAME = 'JobProcessingService',
			@Contract    SYSNAME = 'JobContract',
			@MessageType SYSNAME = 'JobRequest',
			@conversation_handle UNIQUEIDENTIFIER;
 
  BEGIN TRANSACTION;
 
  BEGIN DIALOG CONVERSATION @conversation_handle
    FROM SERVICE @FromService
    TO SERVICE @ToService
    ON CONTRACT @Contract
    WITH ENCRYPTION = OFF;
 
  SEND ON CONVERSATION @conversation_handle
    MESSAGE TYPE @MessageType(@MessageBody);
 
  COMMIT TRANSACTION;
END