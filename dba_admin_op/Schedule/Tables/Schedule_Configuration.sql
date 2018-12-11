CREATE TABLE [Schedule].[Schedule_Configuration] (
    [ID]              INT            IDENTITY (1, 1) NOT NULL,
    [Server]          NVARCHAR (128) NULL,
    [Database]        NVARCHAR (128) NOT NULL,
    [StoredProcedure] NVARCHAR (128) NOT NULL,
    [RunInterval]     INT            NULL,
    [RunDailyHour]    SMALLINT       NULL,
    [IsActive]        BIT            CONSTRAINT [DF_Schedule_Configuration_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_DataIntegrity_ExecSetup] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [CK_Schedule_Configuration_RunDailyHour_Between0_23] CHECK ([RunDailyHour]>=(0) AND [RunDailyHour]<=(23)),
    CONSTRAINT [CK_Schedule_Configuration_RunInterval] CHECK ([RunInterval]>=(10))
);

