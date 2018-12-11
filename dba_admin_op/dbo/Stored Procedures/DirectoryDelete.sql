CREATE PROCEDURE [dbo].[DirectoryDelete]
@path NVARCHAR (MAX)
AS EXTERNAL NAME [FileSystemHelper].[StoredProcedures].[DirectoryDelete]

