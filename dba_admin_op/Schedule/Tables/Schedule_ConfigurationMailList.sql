CREATE TABLE [Schedule].[Schedule_ConfigurationMailList] (
    [ID]   INT            IDENTITY (1, 1) NOT NULL,
    [Mail] NVARCHAR (128) NOT NULL,
    CONSTRAINT [PK_Schedule_ConfigurationMailList] PRIMARY KEY CLUSTERED ([ID] ASC)
);

