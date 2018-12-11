CREATE TABLE [SSIS].[JobExecuteInfo] (
    [ID]                       INT              IDENTITY (1, 1) NOT NULL,
    [JobName]                  NVARCHAR (128)   NOT NULL,
    [StepID]                   INT              NOT NULL,
    [StepName]                 NVARCHAR (128)   NOT NULL,
    [FullDateTime]             DATETIME         NOT NULL,
    [JobDuration]              BIGINT           NULL,
    [PackageRunDuration]       BIGINT           NULL,
    [ElapsedTime]              NVARCHAR (35)    NULL,
    [MessageTime]              DATETIME         NULL,
    [MessageDescription]       NVARCHAR (250)   NULL,
    [MessageSourceDescription] NVARCHAR (150)   NULL,
    [Message]                  NVARCHAR (MAX)   NULL,
    [MessageExecutionStatus]   NVARCHAR (50)    NULL,
    [MessageGenerated]         NVARCHAR (4000)  NULL,
    [PackageName]              NVARCHAR (128)   NULL,
    [PackageStartTime]         DATETIME         NULL,
    [PackageEndTime]           DATETIME         NULL,
    [RunNumber]                UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_JobExecuteInfo] PRIMARY KEY CLUSTERED ([ID] ASC)
);



