CREATE AGGREGATE [dbo].[ufn_Util_clr_ConcToVarbinary](@value INT)
    RETURNS VARBINARY (MAX)
    EXTERNAL NAME [Customs_Util].[Customs_Util.ConcToVarbinary];

