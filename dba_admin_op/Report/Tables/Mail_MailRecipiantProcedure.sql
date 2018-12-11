CREATE TABLE [Report].[Mail_MailRecipiantProcedure] (
    [ProcedureID]     INT NOT NULL,
    [MailRecipiantID] INT NOT NULL,
    CONSTRAINT [FK_Mail_MailRecipiantProcedure_Mail_MailRecipiant] FOREIGN KEY ([MailRecipiantID]) REFERENCES [Report].[Mail_MailRecipiant] ([ID]),
    CONSTRAINT [FK_Mail_MailRecipiantProcedure_Mail_Procedure] FOREIGN KEY ([ProcedureID]) REFERENCES [Report].[Mail_Procedure] ([ID])
);

