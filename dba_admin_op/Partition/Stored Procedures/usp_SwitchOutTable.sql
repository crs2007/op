
-- =============================================
-- Author:		Sharon
-- Create date: 16/02/2016
-- Update date: 23/02/2016 Sharon ' + IIF(@IsTruncate = 1,'PARTITION @PartitionNumber ',N'') + N'
--				03/03/2016 Sharon IF @Debug = 1 
-- Description:	Set Switch Out Table
-- =============================================
CREATE PROCEDURE [Partition].[usp_SwitchOutTable]

(
		@SourceTableName	VARCHAR (255),
		@DestinationTableName VARCHAR(255),
		@PartitionNumber	INT,
		@IsTruncate BIT = 0,
		@Debug bit = 0
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @Query NVARCHAR(max);
	DECLARE @Error NVARCHAR(2048) = N'';
	SELECT @Query = CONCAT(N'ALTER TABLE ',@SourceTableName,N' SWITCH ' + IIF(@IsTruncate = 1,'PARTITION @PartitionNumber ',N'') + N'TO ',@DestinationTableName + N' PARTITION @PartitionNumber;',
IIF(@IsTruncate = 1,N'
TRUNCATE TABLE '+@DestinationTableName+';',N'')
);
	IF @Debug = 1 RAISERROR(@Query,10,1)WITH NOWAIT; 
	-- Run the command
	BEGIN TRY
		EXECUTE sp_executesql @Query,N'@PartitionNumber	INT',@PartitionNumber = @PartitionNumber;
    END TRY
    BEGIN CATCH
			IF @Debug = 1 PRINT @Query;
			SELECT @Error += CONCAT(
        		ERROR_PROCEDURE() ,':: ',
        		ERROR_MESSAGE() )
        	RAISERROR(@Error,16,1);
    END CATCH
	
	RETURN 0
END