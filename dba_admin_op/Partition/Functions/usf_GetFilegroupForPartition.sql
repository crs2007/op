
-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 
-- Description:	Get Filegroup For Partition
-- =============================================
CREATE FUNCTION [Partition].[usf_GetFilegroupForPartition]  (@PartitionSchema VARCHAR(255), @PartitionNumber INT) 
RETURNS VARCHAR(255)
BEGIN

	DECLARE @FileGroup VARCHAR(255);

	SET @FileGroup = NULL;

	-- Get Filegroup from metadata
	SELECT	@FileGroup = ds.name
	FROM	sys.data_spaces ds
			INNER JOIN sys.destination_data_spaces dds ON (ds.data_space_id = dds.data_space_id)
			INNER JOIN sys.partition_schemes ps ON (ps.data_space_id = dds.partition_scheme_id)
	WHERE	destination_id = @PartitionNumber
			AND ps.type_desc = 'PARTITION_SCHEME'
			AND ps.name = @PartitionSchema;

	RETURN @FileGroup;
END