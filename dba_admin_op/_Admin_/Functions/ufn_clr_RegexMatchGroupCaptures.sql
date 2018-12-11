CREATE FUNCTION [_Admin_].[ufn_clr_RegexMatchGroupCaptures]
(@input NVARCHAR (MAX), @pattern NVARCHAR (MAX), @groupName NVARCHAR (MAX))
RETURNS 
     TABLE (
        [Captures] NVARCHAR (4000) NULL)
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegexMatchGroupCaptures]

