CREATE PROCEDURE [dbo].[usp_clr_Util_GetErrorEvent]
@DateFrom DATETIME, @DateTo DATETIME, @ErrorLevel NVARCHAR (11)
AS EXTERNAL NAME [clrEventViewer].[StoredProcedures].[usp_clr_Util_GetErrorEvent]

