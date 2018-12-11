CREATE TABLE [SSIS].[Package] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [PackageName] NVARCHAR (250) NOT NULL,
    [Order]       INT            NULL,
    CONSTRAINT [PK_Package] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

