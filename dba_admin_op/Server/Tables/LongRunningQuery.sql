CREATE TABLE [Server].[LongRunningQuery] (
    [DateTaken]          DATETIME       NOT NULL,
    [Session ID]         INT            NULL,
    [Database Name]      [sysname]      NULL,
    [command]            NVARCHAR (MAX) NULL,
    [statement_text]     NVARCHAR (MAX) NULL,
    [command_text]       NVARCHAR (MAX) NULL,
    [wait_type]          NVARCHAR (60)  NULL,
    [wait_time]          INT            NULL,
    [MB used]            FLOAT (53)     NULL,
    [MB used system]     FLOAT (53)     NULL,
    [MB reserved]        FLOAT (53)     NULL,
    [MB reserved system] FLOAT (53)     NULL,
    [Record count]       INT            NULL
);

