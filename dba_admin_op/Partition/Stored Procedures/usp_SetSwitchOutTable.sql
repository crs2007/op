
-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 
-- Description:	Set Switch Out Table
-- =============================================
CREATE PROCEDURE [Partition].[usp_SetSwitchOutTable]

(
		@SourceTableName	VARCHAR (255),
		@DestinationTableName VARCHAR(255),
		@PartitionNumber	INT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @CompressionQuery VARCHAR(max);
	DECLARE @Compression TINYINT;

	SET @CompressionQuery = '';
	
	-- Find out the Compression of the partition, identified by the ID of the partition
	-- The ID of the partition you can find in the meta data
	-- Filter on Index_id = 1, this is the clustered index
	SELECT	@Compression = data_compression FROM sys.partitions
	WHERE	partition_number = @PartitionNumber
			AND object_id = OBJECT_ID(@SourceTableName)
			AND index_id = 1;

	-- Compression can be 0, 1 or 2. 0 ia none, so nothing to do here
	-- Row Compression is 1
	IF @Compression = 1
	BEGIN
		-- Row compression
		SET @compressionQuery ='
			ALTER TABLE ' + @DestinationTableName + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ROW)';
	END
	-- Page Compression is 2
	ELSE IF @Compression = 2
	BEGIN
		-- Page compression
		SET @compressionQuery ='
			ALTER TABLE ' + @DestinationTableName + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)';
	END
	ELSE -- NO compression
	BEGIN
		-- NO compression
		SET @compressionQuery ='
			ALTER TABLE ' + @DestinationTableName + ' REBUILD PARTITION = ALL';
	END
	-- Run the command
	EXECUTE(@CompressionQuery);
	
	RETURN 0
END