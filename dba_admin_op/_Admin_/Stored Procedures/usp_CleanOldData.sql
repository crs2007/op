-- =============================================
-- Author:		Sharon
-- Create date: 07/04/2016
-- Description:	CleanUP
-- =============================================
CREATE PROCEDURE [_Admin_].[usp_CleanOldData]
	@Date DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF @Date IS NULL SET @Date = DATEADD(DAY,-30,GETDATE());

	BEGIN TRANSACTION
		DELETE FROM [Server].[LongRunningQuery] WHERE [DateTaken] < @Date;
	COMMIT
	BEGIN TRANSACTION
		DELETE FROM [Server].[SessionInfo] WHERE [DateTaken] < @Date;
	COMMIT
END