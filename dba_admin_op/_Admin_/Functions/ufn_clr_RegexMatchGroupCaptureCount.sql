CREATE FUNCTION [_Admin_].[ufn_clr_RegexMatchGroupCaptureCount]
(@input NVARCHAR (MAX), @pattern NVARCHAR (MAX), @groupName NVARCHAR (MAX))
RETURNS INT
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegexMatchGroupCaptureCount]

