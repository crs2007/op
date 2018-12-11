CREATE SERVICE [JobProcessingService]
    AUTHORIZATION [dbo]
    ON QUEUE [dbo].[JobProcessingQueue]
    ([JobContract]);

