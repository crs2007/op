CREATE PROCEDURE [_Admin_].[usp_clr_CleanBuffer]
@ServerName NVARCHAR (128), @DatabaseName NVARCHAR (128), @LoginName NVARCHAR (128), @Password NVARCHAR (128), @ShortSPName NVARCHAR (128), @InnerCLRError NVARCHAR (2048) OUTPUT
AS EXTERNAL NAME [CLR_Util].[StoredProcedures].[usp_clr_CleanBuffer]

