CREATE FUNCTION [dbo].[ufn_Util_clr_SplitStr]
(@Str NVARCHAR (MAX), @Separator NVARCHAR (4000))
RETURNS 
     TABLE (
        [Data] NVARCHAR (4000) NULL)
AS
 EXTERNAL NAME [Customs_Util].[Customs_Util.UserDefinedFunctions].[SplitStr]

