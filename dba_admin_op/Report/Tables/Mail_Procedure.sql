CREATE TABLE [Report].[Mail_Procedure] (
    [ID]            INT       IDENTITY (1, 1) NOT NULL,
    [ProcedureName] [sysname] NOT NULL,
    CONSTRAINT [PK_Mail_Procedure] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

