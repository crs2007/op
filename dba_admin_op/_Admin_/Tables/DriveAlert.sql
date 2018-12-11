CREATE TABLE [_Admin_].[DriveAlert] (
    [ID]          INT       IDENTITY (1, 1) NOT NULL,
    [DriveName]   CHAR (3)  NOT NULL,
    [Description] [sysname] NOT NULL,
    [Percent]     INT       NOT NULL,
    [LastSample]  INT       NULL,
    CONSTRAINT [PK_DriveAlert] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

