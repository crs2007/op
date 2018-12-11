CREATE PROCEDURE [dbo].[FileDelete]
@sFileNamePath NVARCHAR (MAX)
AS EXTERNAL NAME [FileSystemHelper].[StoredProcedures].[FileDelete]

