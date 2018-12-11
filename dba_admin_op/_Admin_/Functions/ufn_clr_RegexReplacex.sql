CREATE FUNCTION [_Admin_].[ufn_clr_RegexReplacex]
(@pattern NVARCHAR (MAX), @input NVARCHAR (MAX), @replacement NVARCHAR (MAX))
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegExReplacex]

