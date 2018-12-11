CREATE QUEUE [dbo].[JobProcessingQueue]
    WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [Schedule].[usp_ProcessingQueueActivation], MAX_QUEUE_READERS = 10, EXECUTE AS N'dbo');

