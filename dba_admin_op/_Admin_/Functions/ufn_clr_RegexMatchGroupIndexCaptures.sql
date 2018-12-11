CREATE FUNCTION [_Admin_].[ufn_clr_RegexMatchGroupIndexCaptures]
(@input NVARCHAR (MAX), @pattern NVARCHAR (MAX), @groupIndex INT)
RETURNS 
     TABLE (
        [Captures] NVARCHAR (4000) NULL)
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegexMatchGroupIndexCaptures]

