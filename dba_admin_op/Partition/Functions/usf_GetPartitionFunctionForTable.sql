
-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 
-- Description:	Get Partition Function For Table
-- =============================================
CREATE FUNCTION [Partition].[usf_GetPartitionFunctionForTable] (@TableName VARCHAR(255))
RETURNS VARCHAR(255)
BEGIN
	DECLARE @PartitionFunction VARCHAR(255);
	DECLARE @Schema VARCHAR(255);

	-- Divide table name in schema and table	
	SELECT @Schema = LEFT(@TableName, PATINDEX('%.%', @TableName) - 1);
	SELECT @TableName = SUBSTRING(@TableName, PATINDEX('%.%', @TableName) + 1 , LEN(@TableName) - PATINDEX('%.%', @TableName));
	
	-- get partition function from the metadata
	SELECT @PartitionFunction = pf.name
		FROM sys.tables t
			INNER JOIN sys.indexes i on t.object_id = i.object_id
			INNER JOIN sys.partition_schemes ps on i.data_space_id = ps.data_space_id
			INNER JOIN sys.partition_functions pf on ps.function_id = pf.function_id
			INNER JOIN sys.schemas s on t.schema_id = s.schema_id
	WHERE	index_id < 2
			AND t.name = @TableName 
			AND s.name = @Schema;

	RETURN @PartitionFunction;
END