CREATE TABLE [Schedule].[Schedule_cl_ConfigurationMailListScheduleTask] (
    [MailID]         INT NOT NULL,
    [ScheduleTaskID] INT NOT NULL,
    CONSTRAINT [FK_Schedule_cl_ConfigurationMailListScheduleTask_Schedule_Configuration] FOREIGN KEY ([ScheduleTaskID]) REFERENCES [Schedule].[Schedule_Configuration] ([ID]),
    CONSTRAINT [FK_Schedule_cl_ConfigurationMailListScheduleTask_Schedule_ConfigurationMailList] FOREIGN KEY ([MailID]) REFERENCES [Schedule].[Schedule_ConfigurationMailList] ([ID])
);

