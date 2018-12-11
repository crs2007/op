CREATE FUNCTION [_Admin_].[ufn_clr_RegexIsMatch]
(@pattern NVARCHAR (MAX), @input NVARCHAR (MAX))
RETURNS BIT
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegExIsMatch]

