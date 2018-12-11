CREATE FUNCTION [dbo].[ufn_Util_clr_RegexReplace]
(@Str NVARCHAR (MAX), @Pattern NVARCHAR (MAX), @Replacement NVARCHAR (MAX), @IsCS BIT)
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [Customs_Util].[Customs_Util.UserDefinedFunctions].[RegexReplace]

