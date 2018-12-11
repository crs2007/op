CREATE FUNCTION [_Admin_].[ufn_clr_RegexMatchGroupIndexAt]
(@input NVARCHAR (MAX), @pattern NVARCHAR (MAX), @groupIndex INT, @captureIndex INT)
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegexMatchGroupIndexAt]

