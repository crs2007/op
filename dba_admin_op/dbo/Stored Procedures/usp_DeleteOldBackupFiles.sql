
--============================
-- xp_delete_file information
--============================
-- xp_delete_file actually checks the file header to see what type of file it is and will only delete certain types such
-- as database and log backups. I suppose they expanded this to certain types of log files as well but as you say this is
-- not documented by MS. Just be aware that it will not delete just any file type

-- First argument is: 
-- 0 - specifies a backup file
-- 1 - specifies a report file 
-- (I'm not sure what the difference between a "backup file" and a "report file" is, since you specify the extension of files
-- you're deleting with the third argument.)
--
-- Fifth argument is whether to delete recursively. 
-- 0 - don't delete recursively (default)
-- 1 - delete files in sub directories
--====================================================================
CREATE PROCEDURE [dbo].[usp_DeleteOldBackupFiles] 
	@BackupFolderLocation VARCHAR(4000),
	@FilesSuffix VARCHAR(3) = 'bak',
	@DaysToDelete SMALLINT = 30
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DeleteDate NVARCHAR(50);
	DECLARE @DeleteDateTime DATETIME;
	DECLARE @FullPath VARCHAR(4000);
	DECLARE @PowerShell VARCHAR(4000);
	DECLARE @Print VARCHAR(4000);
	DECLARE @Error VARCHAR(2048);

	SET @DeleteDateTime = DateAdd(DAY, - @DaysToDelete, GetDate());
	SELECT @DeleteDate = Replace(CONVERT(NVARCHAR(25), @DeleteDateTime, 111), '/', '-') + 'T' + CONVERT(NVARCHAR(25), @DeleteDateTime, 108);
	
	CREATE TABLE #dirtree (ID int IDentity(1,1),Subdirectory VARCHAR(512), Depth INT, ParentID INT);
	INSERT INTO #dirtree (Subdirectory, Depth)
	EXEC xp_dirtree @BackupFolderLocation;
	UPDATE #dirtree
	SET ParentID = (SELECT MAX(ID) FROM #dirtree WHERE Depth = T1.Depth - 1 AND ID < T1.ID)
	FROM #dirtree T1;

	IF EXISTS (SELECT TOP 1 1 FROM #dirtree WHERE Subdirectory = '$RECYCLE.BIN')
	BEGIN 
		;WITH cteDelete AS (
			SELECT	ID
			FROM	#dirtree WHERE Subdirectory = '$RECYCLE.BIN'
			UNION ALL
			SELECT	E.ID
			FROM	#dirtree E
					INNER JOIN cteDelete C ON C.ID = E.ParentID
		)DELETE FROM #dirtree WHERE ID IN (SELECT ID FROM cteDelete);

	END

	;WITH CTE
	AS
	(
		SELECT
			t.ID,
			CAST(t.Subdirectory + '\' AS VARCHAR(MAX)) Subdirectory,
			t.Depth
		FROM
			#dirtree AS t
		WHERE
			Depth = 1
		UNION ALL
		SELECT
			t.ID,
			CAST(CTE.Subdirectory + t.Subdirectory+'\' AS VARCHAR(MAX)),
			t.Depth
		FROM
			#dirtree AS t
			JOIN CTE
				ON CTE.ID=t.parentID
		)
		SELECT ID,@BackupFolderLocation + CTE.Subdirectory AS [FullPath] 
		INTO #DirSubFolder
		FROM CTE ORDER BY ID ASC

	DROP TABLE #dirtree;
	DECLARE curDir CURSOR LOCAL FAST_FORWARD FOR
	SELECT [FullPath] FROM #DirSubFolder ORDER BY ID ASC;
	
	OPEN curDir
	FETCH NEXT FROM curDir INTO @FullPath;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			SET @Print = 'Delete ' + @FullPath + '*.' + @FilesSuffix + ' older than ' + @DeleteDate;
			RAISERROR (@Print, 10, 1) WITH NOWAIT;
			EXECUTE master.dbo.xp_delete_file 0,
				@FullPath,
				@FilesSuffix,
				@DeleteDate,
				1;
		END TRY
		BEGIN CATCH
			SET @Error = ERROR_MESSAGE();
			RAISERROR (@Print, 16, 1) WITH NOWAIT;
			RETURN -1;
		END CATCH
		SET @PowerShell = 'PowerShell.exe -noprofile -command "Get-ChildItem ''' + @FullPath + ''' -recurse | Where {$_.PSIsContainer -and @(Get-ChildItem -LiteralPath:$_.fullname).Count -eq 0} |remove-item"'; 
		EXEC xp_cmdshell @PowerShell,no_output;
		FETCH NEXT FROM curDir INTO @FullPath;
	END

	CLOSE curDir;
	DEALLOCATE curDir;

END