-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 
-- Description:	Set Switch Out Table
-- =============================================
CREATE PROCEDURE [Partition].[usp_CreatePrimaryKeySwitchOutTable]
(
		@SourceTableName		VARCHAR (255),
		@DestinationTableName	VARCHAR (255)
)
AS
BEGIN

	DECLARE @PKColumns		VARCHAR(max);
	DECLARE @ColName		VARCHAR(255);
	DECLARE @AlterQuery		VARCHAR(max);
	DECLARE @PlainTableName	VARCHAR(max);

	SET NOCOUNT ON

	SET @PKColumns = '';
	SET @AlterQuery = '';

	-- Name of Switch Out Tabelle without schema....
	SELECT @PlainTableName = OBJECT_NAME(OBJECT_ID(@DestinationTableName));

	-- Cursor to go through list of PK
	DECLARE xCUR CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
		SELECT col.name AS ColumnName
		FROM sys.key_constraints constr
		INNER JOIN sys.index_columns AS idxCol ON (constr.unique_index_id = idxCol.index_id AND constr.parent_object_id = idxCol.object_id)
		INNER JOIN sys.columns AS col ON (idxCol.column_id = col.column_id AND constr.parent_object_id = col.object_id)
		WHERE constr.parent_object_id = OBJECT_ID(@sourceTableName) AND constr.type = 'PK'
		ORDER BY idxCol.key_ordinal ASC;	

	-- Cursor open
	OPEN xCUR;
	
	-- get actual value into variable
	FETCH NEXT FROM xCUR INTO @ColName;
	
	-- cursor has values
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- The list of columns already has an entry, so add a comma
		IF LEN(@pkColumns) > 0
			SET @pkColumns = @pkColumns + ',';
		
		-- add actual column name in PK
		SET @pkColumns = @pkColumns + @ColName;
	
		-- next row
		FETCH NEXT FROM xCUR INTO @ColName;
	END
	
	-- Cursor close
	CLOSE xCUR;
	-- free cursor memory
	DEALLOCATE xCUR;
	
	-- a PK was found, so add it to the temp table
	IF @pkColumns <> ''
	BEGIN
		-- build alter command
		SET @AlterQuery =  'ALTER TABLE ' + @DestinationTableName + ' ADD';
		SET @AlterQuery = @AlterQuery + ' CONSTRAINT PK_' + @PlainTableName + ' PRIMARY KEY (' + @PKColumns + ')';
		-- run it
		EXECUTE(@AlterQuery);
	END

	RETURN 0
END