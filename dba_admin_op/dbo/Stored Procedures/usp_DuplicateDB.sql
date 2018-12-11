-- =============================================
-- Author:		Sharon Rimer
-- Create date: 10/05/16
-- Description:	DuplicateDB
-- =============================================
CREATE PROCEDURE [dbo].[usp_DuplicateDB]
    @DatabaseNameFrom SYSNAME = 'OP_STG',
	@DatabaseNameTo SYSNAME = 'OP_STG_RENAME'
AS
BEGIN 
	SET NOCOUNT ON;

    IF NOT EXISTS(SELECT TOP 1 1
	FROM	sys.databases d
	WHERE	d.name = @DatabaseNameFrom)
	BEGIN
		RAISERROR('@DatabaseNameFrom Does not Exists in this Server!',16,1);
		RETURN -1;
	END
	IF @DatabaseNameFrom = @DatabaseNameTo
	BEGIN
		RAISERROR('@DatabaseNameFrom Can not be same as @DatabaseNameTo!',16,1);
		RETURN -1;
	END
	IF @DatabaseNameFrom IS NULL OR  @DatabaseNameTo IS NULL
	BEGIN
		RAISERROR('@DatabaseNameFrom or @DatabaseNameTo Can Not be NULL!',16,1);
		RETURN -1;
	END

	DECLARE @sql nvarchar(max)
	DECLARE @Path nvarchar(1000);

	SET @Path = N'F:\Temp\' + @DatabaseNameFrom + N'.bak';


	BACKUP DATABASE @DatabaseNameFrom TO  DISK = @Path 
	WITH  COPY_ONLY, NOFORMAT, INIT,  SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  
	STATS = 10


	CREATE TABLE #BackupFiles
	(LogicalName varchar(255),
	PhysicalName varchar(255),
	Type char(1),
	FileGroupName varchar(50),
	Size bigint,
	MaxSize bigint,
	FileId int,
	CreateLSN numeric(30,2),
	DropLSN numeric(30,2),
	UniqueId uniqueidentifier,
	ReadOnlyLSN numeric(30,2),
	ReadWriteLSN numeric(30,2),
	BackupSizeInBytes bigint,
	SourceBlockSize int,
	FileGroupId int,
	LogGroupGUID uniqueidentifier,
	DifferentialBaseLSN numeric(30,2),
	DifferentialBaseGUID uniqueidentifier,
	IsReadOnly int,
	IsPresent int,
	TDEThumbprint varchar(10))
 
	-- Execute above created SP to get the RESTORE FILELISTONLY output into a table
	 insert into #BackupFiles
	EXEC('RESTORE FileListOnly FROM DISK = '''+ @Path +'''') 
 
	-- Build the T-SQL RESTORE statement
	set @sql = 'RESTORE DATABASE ' + QUOTENAME(@DatabaseNameTo) + char(13) + 'FROM DISK = ''' + @Path +  ''' WITH STATS = 1, '
 
	select @sql += char(13) + 'MOVE ''' + LogicalName + ''' TO ''' + REPLACE(PhysicalName,LogicalName + '.' + RIGHT(PhysicalName,CHARINDEX('\',PhysicalName)),'') + REPLACE(LogicalName,@DatabaseNameFrom,@DatabaseNameTo) + '.' + RIGHT(PhysicalName,CHARINDEX('\',PhysicalName)) + ''','
	from #BackupFiles
	where IsPresent = 1
 
	set @sql += --SUBSTRING(@sql,1,LEN(@sql)-1) + 
'
NOUNLOAD,  REPLACE,  STATS = 5;'
 
-- Get the RESTORE DATABASE command
DECLARE @kill varchar(8000) = '';
SELECT	@kill = @kill + 'kill ' + CONVERT(varchar(5), spid) + ';'
FROM	master..sysprocesses 
WHERE	dbid = db_id(@DatabaseNameTo)

EXEC(@kill);
exec sp_executesql @sql
DROP TABLE #BackupFiles

END