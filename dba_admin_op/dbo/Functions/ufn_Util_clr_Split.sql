CREATE FUNCTION [dbo].[ufn_Util_clr_Split]
(@Data NVARCHAR (4000))
RETURNS 
     TABLE (
        [Data] INT NULL)
AS
 EXTERNAL NAME [Customs_Util].[Customs_Util.UserDefinedFunctions].[Split]

