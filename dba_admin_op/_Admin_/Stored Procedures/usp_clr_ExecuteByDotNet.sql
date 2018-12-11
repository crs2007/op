CREATE PROCEDURE [_Admin_].[usp_clr_ExecuteByDotNet]
@ServerName NVARCHAR (128), @DatabaseName NVARCHAR (128), @LoginName NVARCHAR (128), @Password NVARCHAR (128), @TSQL NVARCHAR (MAX), @Timeout INT, @Duration INT OUTPUT
AS EXTERNAL NAME [CLR_Util].[CLR_Util.StoredProcedures].[usp_clr_ExecuteByDotNet]

