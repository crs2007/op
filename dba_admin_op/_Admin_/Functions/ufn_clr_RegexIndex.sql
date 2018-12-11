CREATE FUNCTION [_Admin_].[ufn_clr_RegexIndex]
(@pattern NVARCHAR (MAX), @input NVARCHAR (MAX))
RETURNS INT
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegExIndex]

