
-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 
-- Description:	Drop Switch Out Table
-- =============================================
CREATE PROCEDURE [Partition].[usp_DropSwitchOutTable]
(
	@DestinationTableName as varchar(255)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Query VARCHAR(max);

	SET @Query = '';

	SET @Query = 'IF (OBJECT_ID(''' + @DestinationTableName + ''') IS NOT NULL) DROP TABLE ' + @DestinationTableName;
	EXECUTE (@Query);

	RETURN 0;
END