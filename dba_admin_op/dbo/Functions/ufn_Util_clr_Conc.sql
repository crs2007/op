CREATE AGGREGATE [dbo].[ufn_Util_clr_Conc](@value NVARCHAR (MAX))
    RETURNS NVARCHAR (MAX)
    EXTERNAL NAME [Customs_Util].[Customs_Util.Conc];

