CREATE PROCEDURE [dbo].[usp_clr_GetServerPrincipals]
@ServerName NVARCHAR (128), @LoginName NVARCHAR (128), @Password NVARCHAR (128), @InnerCLRError NVARCHAR (2048) OUTPUT
AS EXTERNAL NAME [CLR_Util].[CLR_Util.StoredProcedures].[usp_clr_GetServerPrincipals]

