﻿-- =============================================
-- Author:		Sharon Rimer
-- Create date: 13/01/2016
-- Description:	Remove Database
-- =============================================
CREATE PROCEDURE [dbo].[usp_DeleteDB]
    @DatabaseName SYSNAME,
	@Exec BIT = 0
AS
BEGIN 
	SET NOCOUNT ON;
    DECLARE 
        @CRLF VARCHAR(100)= '
',
        @ExecSQL NVARCHAR(MAX)= '',
		@Print NVARCHAR(2048);


	IF NOT EXISTS(select TOP 1 1 from sys.databases where [name] = @DatabaseName)
	BEGIN
	    SET @Print = 'No DB - ' + @DatabaseName + ' has been found on this server.';
		RAISERROR(@Print,10,1) WITH NOWAIT;
		RETURN -1;
	END

	IF @Exec = 1
	BEGIN
		SET @Print = 'Killing active connections to the "' + @DatabaseName + '" database';
		RAISERROR(@Print,10,1) WITH NOWAIT;

		-- Create the sql to kill the active database connections
		SET @ExecSQL = ''
		SELECT   @ExecSQL = @ExecSQL + 'kill ' + CONVERT(CHAR(10), spid) + ' '
		FROM     master.dbo.sysprocesses
		WHERE    DB_NAME(dbid) = @DatabaseName AND DBID <> 0 AND spid <> @@spid

		EXEC (@ExecSQL);
	END

    SELECT	@ExecSQL = 'DROP DATABASE ' + QUOTENAME([name]) + ';' + @CRLF
	FROM	sys.databases 
	WHERE	[name] = @DatabaseName	
			AND [state] = 0;

	IF @Exec = 1
	BEGIN
		BEGIN TRY
			EXEC master.sys.sp_executesql @ExecSQL
			SET @Print = 'Finish Seccessfuly!';
			RAISERROR(@Print,10,1) WITH NOWAIT;
		END TRY
		BEGIN CATCH
			THROW;
		END CATCH
	END
	ELSE
	BEGIN
		PRINT '---------------------------'
		EXEC [dbo].[PrintMax] @ExecSQL
		PRINT '---------------------------'
	END
END