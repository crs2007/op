-- =============================================
-- Author:		Sharon Rimer
-- Create date: 13/01/2016
-- Description:	Restore Backup file to server location
-- =============================================
CREATE PROCEDURE [dbo].[usp_KillUsersOnDB]
    @DBName SYSNAME
AS
BEGIN 
   
	CREATE TABLE #TmpWho
	(spid INT, ecid INT, status VARCHAR(150), loginame VARCHAR(150),
	hostname VARCHAR(150), blk INT, dbname VARCHAR(150), cmd VARCHAR(150),request_id INT)
	INSERT INTO #TmpWho
	EXEC sp_who;

	DECLARE @spid INT
	DECLARE @tString VARCHAR(15)
	DECLARE @getspid CURSOR --LOCAL FAST_FORWARD
	SET @getspid =   CURSOR FOR
	SELECT spid
	FROM #TmpWho
	WHERE dbname = @DBName OPEN @getspid

	FETCH NEXT FROM @getspid INTO @spid
	WHILE @@FETCH_STATUS = 0
	BEGIN
	SET @tString = 'KILL ' + CAST(@spid AS VARCHAR(5))
		BEGIN TRY
			EXEC(@tString);
		END TRY
		BEGIN CATCH
		END CATCH
		FETCH NEXT FROM @getspid INTO @spid
	END
	CLOSE @getspid
	DEALLOCATE @getspid
	DROP TABLE #TmpWho
END