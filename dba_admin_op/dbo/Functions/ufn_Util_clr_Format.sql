CREATE FUNCTION [dbo].[ufn_Util_clr_Format]
(@Str NVARCHAR (4000), @ArgsCSV NVARCHAR (4000))
RETURNS NVARCHAR (4000)
AS
 EXTERNAL NAME [Customs_Util].[Customs_Util.UserDefinedFunctions].[Format]

