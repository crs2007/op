CREATE PROCEDURE [dbo].[DirectoryDeleteContents]
@path NVARCHAR (MAX), @daysToKeep SMALLINT, @fileExtension NVARCHAR (MAX)
AS EXTERNAL NAME [FileSystemHelper].[StoredProcedures].[DirectoryDeleteContents]

