CREATE PROCEDURE [dbo].[FileRead]
@sFileNamePath NVARCHAR (MAX), @output NVARCHAR (MAX) OUTPUT
AS EXTERNAL NAME [FileSystemHelper].[StoredProcedures].[FileRead]

