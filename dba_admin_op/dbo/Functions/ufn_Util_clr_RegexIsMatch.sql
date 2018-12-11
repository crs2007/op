CREATE FUNCTION [dbo].[ufn_Util_clr_RegexIsMatch]
(@Str NVARCHAR (4000), @pattern NVARCHAR (4000))
RETURNS BIT
AS
 EXTERNAL NAME [Customs_Util].[Customs_Util.UserDefinedFunctions].[RegexIsMatch]

