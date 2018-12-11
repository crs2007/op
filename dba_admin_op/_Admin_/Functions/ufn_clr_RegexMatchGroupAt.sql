CREATE FUNCTION [_Admin_].[ufn_clr_RegexMatchGroupAt]
(@input NVARCHAR (MAX), @pattern NVARCHAR (MAX), @groupName NVARCHAR (MAX), @captureIndex INT)
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegexMatchGroupAt]

