CREATE TABLE [Schedule].[Log_ScheduleTaskLog] (
    [ID]                    INT            IDENTITY (1, 1) NOT NULL,
    [ScheduleTaskID]        INT            NULL,
    [TaskStatus]            [sysname]      NOT NULL,
    [StartDate]             DATETIME       NULL,
    [EndDate]               DATETIME       NULL,
    [EffectedRows]          BIGINT         NULL,
    [AdditionalInformation] NVARCHAR (MAX) NULL
);

