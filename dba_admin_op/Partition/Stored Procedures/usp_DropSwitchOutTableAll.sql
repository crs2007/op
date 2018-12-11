-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 
-- Description:	Drop Switch Out Table
-- =============================================
CREATE PROCEDURE [Partition].[usp_DropSwitchOutTableAll]
(
	@DestinationTableName AS VARCHAR(255)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @Query VARCHAR(MAX);

	SET @Query = '';


	SELECT	@Query = @Query + 'IF (OBJECT_ID(''' + s.name + '.' + t.name + ''') IS NOT NULL) DROP TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ';
'
	FROM	sys.tables t
			INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
	WHERE	s.name COLLATE DATABASE_DEFAULT = 'Temp'
			AND t.name LIKE @DestinationTableName + '%';

	EXECUTE (@Query);

	RETURN 0;
END