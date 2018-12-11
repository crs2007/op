CREATE FUNCTION [dbo].[DirectoryList]
(@path NVARCHAR (MAX), @filter NVARCHAR (MAX))
RETURNS 
     TABLE (
        [Name]         NVARCHAR (4000) NULL,
        [Directory]    BIT             NULL,
        [Size]         BIGINT          NULL,
        [DateCreated]  DATETIME        NULL,
        [DateModified] DATETIME        NULL,
        [Extension]    NVARCHAR (4000) NULL)
AS
 EXTERNAL NAME [FileSystemHelper].[UserDefinedFunctions].[DirectoryList]

