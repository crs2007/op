-- =============================================
-- Author:		Sharon Rimer
-- Create date: 25/02/2016
-- Update date: 30/03/2017 Sharon remuve file before execute
-- Description:	Backup file to server location
-- =============================================
CREATE PROCEDURE [dbo].[usp_BackupDB]
    @DBName SYSNAME,
	@Path VARCHAR(1024) = '',
	@COPY_ONLY BIT = 1,
	@COMPRESSION BIT = 1,
	@debug bit = 0
AS
BEGIN 
	SET NOCOUNT ON;
	
    DECLARE @ExecSQL NVARCHAR(MAX) ='';
	DECLARE @BackupPath NVARCHAR(1000) ='';
	SELECT @BackupPath = IIF(@Path = '','N''J:\TempBackup\' + @DBName +'\' + @DBName +'.bak''','N''' + @Path +'\' + @DBName +'.bak''');

	DECLARE @Command nvarchar(256);
	DECLARE @FileExists int;
	SET @Command = 'del ' + @BackupPath;
	EXEC master..xp_FileExist @BackupPath, @FileExists OUT;
	IF @FileExists = 1
		EXEC master..xp_cmdShell @Command;

	IF RIGHT(@Path,1) = '\'
		SELECT @Path = LEFT(@Path,LEN(@Path)-1);

	SELECT @ExecSQL = N'BACKUP DATABASE ' + QUOTENAME(@DBName) +' TO  
DISK = ' + @BackupPath + '
WITH  ' + IIF(@COPY_ONLY = 1,'COPY_ONLY,','') +' NOFORMAT, INIT, SKIP, NOREWIND, NOUNLOAD, ' + IIF(@COMPRESSION = 1,'COMPRESSION,','') + ' STATS = 10;';

	IF @debug = 1
		EXEC dbo.PrintMax @ExecSQL;
	ELSE
		EXEC master.sys.sp_executesql @ExecSQL;
END