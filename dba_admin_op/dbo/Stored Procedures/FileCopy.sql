CREATE PROCEDURE [dbo].[FileCopy]
@sExistingFileNamePath NVARCHAR (MAX), @sNewFileNamePath NVARCHAR (MAX), @bOverwrite BIT
AS EXTERNAL NAME [FileSystemHelper].[StoredProcedures].[FileCopy]

