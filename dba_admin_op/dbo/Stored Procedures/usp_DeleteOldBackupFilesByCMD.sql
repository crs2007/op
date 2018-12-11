CREATE PROCEDURE usp_DeleteOldBackupFilesByCMD
	@BackupFolderLocation VARCHAR(MAX),
	@FilesSuffix VARCHAR(3) = 'bak',
	@DaysToDelete SMALLINT = 30
AS
BEGIN
 DECLARE @delCommand VARCHAR(400)

 IF UPPER (@FilesSuffix) IN ('BAK','TRN') 
 BEGIN
  SET @delCommand = CONCAT('FORFILES /p ' ,
    @BackupFolderLocation,
    ' /s /m '  ,
    '*.'   , 
    @FilesSuffix ,
    ' /d '  ,
    '-'   , 
    ltrim(Str(@DaysToDelete)),
    ' /c ' ,
    '"'  ,
    'CMD /C del /Q /F @FILE',
    '"')

  PRINT @delCommand
  EXEC sys.xp_cmdshell @delCommand
 END
END