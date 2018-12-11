CREATE PROCEDURE [dbo].[DirectoryCreate]
@path NVARCHAR (MAX)
AS EXTERNAL NAME [FileSystemHelper].[StoredProcedures].[DirectoryCreate]

