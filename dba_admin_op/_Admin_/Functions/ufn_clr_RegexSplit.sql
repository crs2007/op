CREATE FUNCTION [_Admin_].[ufn_clr_RegexSplit]
(@input NVARCHAR (MAX), @pattern NVARCHAR (MAX))
RETURNS 
     TABLE (
        [Split] NVARCHAR (4000) NULL)
AS
 EXTERNAL NAME [CLR_Util].[CLR_Util.SqlServerRegex].[RegexSplit]

