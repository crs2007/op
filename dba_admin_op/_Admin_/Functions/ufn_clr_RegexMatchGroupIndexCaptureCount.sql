CREATE FUNCTION [_Admin_].[ufn_clr_RegexMatchGroupIndexCaptureCount]
(@input NVARCHAR (MAX), @pattern NVARCHAR (MAX), @groupIndex INT)
RETURNS INT
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegexMatchGroupIndexCaptureCount]

