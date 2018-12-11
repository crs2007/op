CREATE PROCEDURE [_Admin_].[usp_clr_GetSPParameterTypeByDotNet]
@ServerName NVARCHAR (128), @DatabaseName NVARCHAR (128), @LoginName NVARCHAR (128), @Password NVARCHAR (128), @ShortSPName NVARCHAR (128), @ShartSPSchema NVARCHAR (128)
AS EXTERNAL NAME [CLR_Util].[CLR_Util.StoredProcedures].[usp_clr_GetSPParameterTypeByDotNet]

