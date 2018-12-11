-- =============================================
-- Author:		Sharon Rimer
-- Create date: 13/01/2016
-- Description:	Restore Backup file to server location
-- =============================================
CREATE PROCEDURE [dbo].[usp_HADR_RemoveAllDBFromAG]
	@AvailabilityGroupName sysname = 'Sp10Qa',
	@Exec BIT = 0
AS
BEGIN 
	SET NOCOUNT ON;
	DECLARE @ExecSQL NVARCHAR(max) = N'USE master;';
	DECLARE @CRLF NVARCHAR(5) = N'
	';
	SELECT  @ExecSQL += CONCAT(@CRLF,'ALTER AVAILABILITY GROUP ',QUOTENAME(AG.name),' REMOVE DATABASE ',QUOTENAME(dbcs.database_name),';')
	FROM    master.sys.availability_groups AS AG
			LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states AS agstates ON AG.group_id = agstates.group_id
			INNER JOIN master.sys.availability_replicas AS AR ON AG.group_id = AR.group_id
			INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates ON AR.replica_id = arstates.replica_id
																  AND arstates.is_local = 1
			INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs ON arstates.replica_id = dbcs.replica_id
			LEFT OUTER JOIN master.sys.dm_hadr_database_replica_states AS dbrs ON dbcs.replica_id = dbrs.replica_id
																  AND dbcs.group_database_id = dbrs.group_database_id
	WHERE	AG.name = @AvailabilityGroupName
			AND ISNULL(dbcs.is_database_joined, 0) = 1

	IF @Exec = 1
	BEGIN
		EXEC master.sys.sp_executesql @ExecSQL;
	END
	ELSE
	BEGIN
		PRINT '---------------------------'
		EXEC [dbo].[PrintMax] @ExecSQL;
		PRINT '---------------------------'
	END
END