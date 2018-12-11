CREATE FUNCTION [_Admin_].[ufn_clr_RegexMatch]
(@pattern NVARCHAR (MAX), @input NVARCHAR (MAX))
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegExMatch]

