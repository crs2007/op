-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 03/03/2016
-- Description:	Create Switch Out Table
-- =============================================
CREATE PROCEDURE [Partition].[usp_CreateSwitchOutTable]
(
	@SourceTableName		VARCHAR(255),
	@DestinationTableName	VARCHAR(255),
	@FileGroup VARCHAR(255)
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @Query				VARCHAR(max);
	DECLARE @CompColumn			BIT;
	DECLARE @ColumnName			VARCHAR(255);
	DECLARE @Nullable			BIT;
	DECLARE @Computed			BIT;
	DECLARE @ColumnType			VARCHAR(255);
	DECLARE @ColLength			SMALLINT;
	DECLARE @ColPrecision		SMALLINT;
	DECLARE @ColScale			SMALLINT;
	DECLARE @ComputedDefinition VARCHAR(max);
	DECLARE @With				VARCHAR(max);

	EXEC [Partition].[usp_DropSwitchOutTable] @DestinationTableName;

    SELECT  TOP 1 @With = p.[data_compression_desc] 
    FROM    sys.partitions p 
            INNER JOIN sys.objects o ON p.object_id = o.object_id
    WHERE   data_compression > 0
			AND p.[index_id] IN (0,1)
            AND o.object_id = object_id(@SourceTableName);
	IF LEN(@With) > 1 
	BEGIN
	    SET @With = ' WITH (DATA_COMPRESSION = ' + @With + ')'
	END
	SET @Query = '';
	
	-- target table exists, so drop
	SET @Query = 'IF (OBJECT_ID(''' + @DestinationTableName + ''') IS NOT NULL) DROP TABLE ' + @DestinationTableName;
	-- run query
	EXECUTE (@Query);

	-- Reset the query text
	SET @Query = '';

	IF @FileGroup IS NULL
	SELECT	@FileGroup = ds.name + '(' + c.name + ')'
    FROM	sys.tables t
			INNER JOIN sys.indexes i ON i.object_id = t.object_id
			INNER JOIN	sys.data_spaces ds ON ds.data_space_id = i.data_space_id
			CROSS APPLY(SELECT TOP 1 c.name FROM sys.index_columns  ic inner join  sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
	where	i.object_id = ic.object_id
			and ic.index_id = i.index_id
			and ic.partition_ordinal > 0)c
	WHERE	t.object_id = object_id(@SourceTableName);

	-- Read the columns of the source table in order of the columns from left to right into cursor
	DECLARE xCUR CURSOR LOCAL FAST_FORWARD FOR
	SELECT	sc1.name AS ColumnName, sc1.is_nullable AS Nullable,
			sc1.is_computed AS Computed, sct.name AS ColumnType,
			sc1.max_length AS ColLength, sc1.precision AS ColPrecision, sc1.scale AS ColScale,
			ISNULL(sc2.definition,'') AS ComputedDefinition 
	FROM	sys.columns sc1
			INNER JOIN sys.types sct ON sc1.user_type_id = sct.user_type_id
			LEFT JOIN sys.computed_columns sc2 ON sc2.[object_id] = sc1.[object_id] AND sc2.[column_id] = sc1.[column_id]
	WHERE	sc1.[object_id] = object_id(@SourceTableName)
	ORDER BY sc1.column_id;

	-- open cursor
	OPEN xCUR;

	-- read first row
	FETCH NEXT FROM xCUR INTO @ColumnName, @Nullable,
		@Computed, @ColumnType, @ColLength, @ColPrecision, @ColScale, @ComputedDefinition;
	
	-- first row was read
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Query already has columns, so add a comma for the column list
		IF LEN(@Query) > 0 SET @Query = @Query + ','
			-- Query is empty, so start with create table...
			ELSE SET @Query = 'CREATE TABLE ' + @DestinationTableName  + ' (';
	
		-- Add a space
		SET @Query = @Query + @ColumnName + ' ';

		-- Is te column computed
		IF @Computed = 0
		BEGIN	
			IF @ColumnType IN ('numeric', 'decimal')
			BEGIN
				-- if numeric or decimal, work with precision and scale
				SET @Query = @Query + @ColumnType + '(' + CAST(@ColPrecision AS VARCHAR(10)) + ',' + CAST(@ColScale AS VARCHAR(10)) + ') '
			END
			ELSE IF @ColumnType IN ('nchar','nvarchar')
			BEGIN
				-- it is a string data type, so add the length
				SET @Query = @Query + @ColumnType + '(' + CAST(@ColLength/2 AS VARCHAR(10)) + ') '
			END
			ELSE IF @ColumnType IN ('char','varchar')
			BEGIN
				-- it is a string data type, so add the length
				SET @Query = @Query + @ColumnType + '(' + CAST(@ColLength AS VARCHAR(10)) + ') '
			END
			ELSE IF @ColumnType = 'time'
			BEGIN
				-- Time datatype, use scale
				SET @Query = @Query + @ColumnType + '(' + CAST(@ColScale AS VARCHAR(10)) + ') '
			END
			ELSE
			BEGIN
				-- numeric datatype without length
				SET @Query = @Query + @ColumnType + ' ';
			END 
			
			-- if nullable set null, else not null
			IF @Nullable = 1 SET @Query = @Query + 'NULL'
				ELSE SET @Query = @Query + 'NOT NULL';
		END
		ELSE
		BEGIN
			-- Computed Column, so use its definition from the meta data
			SET @Query = @Query + ' AS ' + @ComputedDefinition + ' ' ;
		END

		-- read next row from cursor
		FETCH NEXT FROM xCUR INTO @ColumnName, @Nullable,
			@Computed, @ColumnType, @ColLength, @ColPrecision, @ColScale, @ComputedDefinition;
	END

	-- close cursor and free memory
	CLOSE xCUR;
	DEALLOCATE xCUR;

	-- a Query is there, so go on...
	IF LEN(@Query) > 0
	BEGIN
		-- add the Filegroup, the table must be in the same as the partition
		SET @Query = @Query + ') ON ' + @FileGroup;
		IF LEN(@With) > 1 
		BEGIN
		   SET @Query = @Query + ISNULL(@With,''); 
		END
		SET @Query = @Query + ';';
	END
	PRINT @Query
	-- a Query is there, so run it...
	IF LEN(@Query) > 0
		EXECUTE (@Query);

	RETURN 0;
END