CREATE TABLE [Server].[SessionInfo] (
    [DateTaken]                 DATETIME       NOT NULL,
    [dd hh:mm:ss.mss]           VARCHAR (15)   NULL,
    [SessionID]                 INT            NULL,
    [Database Name]             [sysname]      NULL,
    [StoredProcedure]           VARCHAR (255)  NULL,
    [HostName]                  [sysname]      NOT NULL,
    [LoginName]                 [sysname]      NULL,
    [ProgramName]               VARCHAR (255)  NULL,
    [ConnectionMethud]          [sysname]      NULL,
    [Status]                    [sysname]      NULL,
    [WaitType]                  VARCHAR (255)  NULL,
    [TransactionIsolationLevel] NVARCHAR (MAX) NULL,
    [Command]                   NVARCHAR (MAX) NULL,
    [CommandText]               NVARCHAR (MAX) NULL,
    [KillThatMotherFuker]       NVARCHAR (25)  NULL
);

