-- =============================================
-- Author:		Sharon Rimer
-- Create date: 25/04/2017
-- Description:	Set tempdb data files to be at the same size
-- =============================================
CREATE PROCEDURE [dbo].[usp_SetTempDBFileToSameSize]
    @Size SMALLINT,--MB
	@Exec BIT = 0
AS
BEGIN 
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE 
        @CRLF NVARCHAR(100)= N'
',
        @ExecSQL NVARCHAR(MAX)= N'',
		@Print NVARCHAR(2048);
		SET @Print = N'Turn trace flage 1117 on!';
	
	IF @Size BETWEEN 100 AND 10000
	BEGIN
		IF OBJECT_ID('tempdb..#TRACESTATUS') IS NOT NULL DROP TABLE #TRACESTATUS;

		CREATE TABLE #TRACESTATUS
		(
		TraceFlag	INT,
		[Status] INT,
			[Global]	INT,
			[Session] INT,
		)
		SELECT @ExecSQL = N'dbcc TRACESTATUS(1117);' 
		INSERT INTO #TRACESTATUS EXEC (@ExecSQL);


		IF LEFT(CONVERT(NVARCHAR(1000),SERVERPROPERTY('ProductVersion')),2) < 13 -- SQL Server 2016
			AND NOT EXISTS (SELECT TOP 1 1 FROM #TRACESTATUS WHERE [Session] = 1 AND [Global] = 1)
		BEGIN
			PRINT @Print;
		END
		SET @ExecSQL += N'
USE [tempdb]
GO
CHECKPOINT;
CHECKPOINT;
CHECKPOINT;
CHECKPOINT;
CHECKPOINT;
CHECKPOINT;
GO
';
		SELECT	@ExecSQL += N'DBCC SHRINKFILE (N''' + [name] + N''' , ' + CONVERT(NVARCHAR(5),@Size) + N');
GO
'
		FROM	sys.master_files
		WHERE	database_id = 2
				AND [type] = 0
				AND [state] = 0;

		IF @Exec = 1
		BEGIN
			BEGIN TRY
				EXECUTE sys.sp_executesql @ExecSQL;
			
				SET @Print = N'';
				--sys.master_files.size(Stored values in pages): pages = MB * 128
				IF EXISTS (SELECT	TOP 1 1
				FROM	sys.master_files
				WHERE	database_id = 2
						AND [type] = 0
						AND [state] = 0
						AND size != @Size * 128)
				BEGIN
					SELECT	@Print += 'File ' + name + ' failed to shrink. Current size is ' + CONVERT(NVARCHAR(5),size/128) + N'MB.
	'
					FROM	sys.master_files
					WHERE	database_id = 2
							AND [type] = 0
							AND [state] = 0
							AND size != @Size * 128;
					PRINT @ExecSQL;
				END
				ELSE
				BEGIN
					SET	@Print = 'All data files in tempdb has been shrunk successfully!';
					PRINT @Print;
				END
			
			END TRY
			BEGIN CATCH
				THROW;
			END CATCH
		END
		ELSE
		BEGIN
			PRINT '---------------------------'
			EXEC [dbo].[PrintMax] @ExecSQL;
			PRINT '---------------------------'
		END
	END
	ELSE
		PRINT '@Size should be between 100MB to 10000MB';
END