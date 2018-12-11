CREATE QUEUE [dbo].[JobRequestQueue]
    WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [Schedule].[usp_RequestQueueActivation], MAX_QUEUE_READERS = 10, EXECUTE AS N'dbo');

