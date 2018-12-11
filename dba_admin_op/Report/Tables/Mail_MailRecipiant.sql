CREATE TABLE [Report].[Mail_MailRecipiant] (
    [ID]       INT           IDENTITY (1, 1) NOT NULL,
    [Name]     NVARCHAR (30) NOT NULL,
    [Email]    VARCHAR (50)  NOT NULL,
    [Category] VARCHAR (128) NULL,
    CONSTRAINT [PK_Mail_MailRecipiant] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

