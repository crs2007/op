CREATE FUNCTION [_Admin_].[ufn_clr_RegexReplace]
(@input NVARCHAR (MAX), @pattern NVARCHAR (MAX), @replacement NVARCHAR (MAX))
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegExReplace]

