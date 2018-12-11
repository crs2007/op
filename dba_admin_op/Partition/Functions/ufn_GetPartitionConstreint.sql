
-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [Partition].[ufn_GetPartitionConstreint] (
	@ObjectName NVARCHAR(255), 
	@PartitionNumber INT
)
RETURNS nvarchar(MAX)
BEGIN
	DECLARE @cmd nvarchar(MAX);
	-- View Partitioned Table information
	SELECT  @cmd = ' CHECK (' + c.name + ' = ''' + CONVERT(nvarchar(max),prv.[value]) + ''');'
	FROM	sys.dm_db_partition_stats AS pstats
			INNER JOIN sys.partitions AS p ON pstats.partition_id = p.partition_id
			INNER JOIN sys.destination_data_spaces AS dds ON pstats.partition_number = dds.destination_id
			INNER JOIN sys.data_spaces AS ds ON dds.data_space_id = ds.data_space_id
			INNER JOIN sys.partition_schemes AS ps ON dds.partition_scheme_id = ps.data_space_id
			INNER JOIN sys.partition_functions AS pf ON ps.function_id = pf.function_id
			INNER JOIN sys.indexes AS i ON pstats.object_id = i.object_id AND pstats.index_id = i.index_id AND dds.partition_scheme_id = i.data_space_id AND i.type <= 1 /* Heap or Clustered Index */
			INNER JOIN sys.index_columns AS ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id AND ic.partition_ordinal >= 0
			INNER JOIN sys.columns AS c ON pstats.object_id = c.object_id AND ic.column_id = c.column_id
			LEFT JOIN sys.partition_range_values AS prv ON pf.function_id = prv.function_id AND pstats.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id+1) END)
	WHERE	pstats.object_id =  object_id(@ObjectName) 
			AND @PartitionNumber = pstats.partition_number;
	RETURN @cmd;
END