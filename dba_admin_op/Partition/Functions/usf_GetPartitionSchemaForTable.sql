
-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 
-- Description:	Set Switch Out Table
-- =============================================
CREATE FUNCTION [Partition].[usf_GetPartitionSchemaForTable] (@TableName VARCHAR(255))
RETURNS VARCHAR(255)
BEGIN
	DECLARE @PartitionSchema VARCHAR(255);
	DECLARE @Schema VARCHAR(255);

	-- divide tablename in schema and tablename
	SELECT @Schema = LEFT(@TableName, PATINDEX('%.%', @TableName) - 1);
	SELECT @TableName = SUBSTRING(@TableName, PATINDEX('%.%', @TableName) + 1 , LEN(@TableName) - PATINDEX('%.%', @TableName));
	
	-- get PartitionSchema
	SELECT @PartitionSchema = ps.name
	FROM	sys.tables t
			INNER JOIN sys.indexes i on t.object_id = i.object_id
			INNER JOIN sys.partition_schemes ps on i.data_space_id = ps.data_space_id
			INNER JOIN sys.partition_functions pf on ps.function_id = pf.function_id
			INNER JOIN sys.schemas s on t.schema_id = s.schema_id
	WHERE	index_id < 2
			AND t.name = @TableName 
			AND s.name = @Schema;

	RETURN @PartitionSchema;
END