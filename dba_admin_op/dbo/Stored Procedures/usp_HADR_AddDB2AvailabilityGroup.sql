-- =============================================
-- Author:		Sharon Rimer
-- Create date: 24/05/2017
-- Description:	Add DB 2 Availability Group
-- =============================================
CREATE PROCEDURE [dbo].[usp_HADR_AddDB2AvailabilityGroup]
	@SharePath NVARCHAR(1000),
	@DatabaseName sysname ,
	@AvailabilityGroupName sysname = NULL 
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @PrimaryReplica sysname;
DECLARE @Time NVARCHAR(25),
		@showadvanced INT  = 0,
		@cmdshell INT = 0,
		@cmdForShell VARCHAR(8000),
		@PrintNote NVARCHAR(2048),
		@CRLF NVARCHAR(5);
DECLARE @cmdOutput TABLE(line NVARCHAR(255));
SELECT @Time = '_' + FORMAT(GETDATE(),'HHmmss');
SET @CRLF = N'
';
IF (SELECT COUNT(1) FROM master.sys.availability_groups) = 1 AND @AvailabilityGroupName IS NULL
BEGIN
    SELECT	@AvailabilityGroupName = AG.name
    FROM	master.sys.availability_groups AS AG
END

SELECT	@PrimaryReplica = agstates.primary_replica
FROM	master.sys.availability_groups AS AG
		INNER JOIN master.sys.dm_hadr_availability_group_states AS agstates ON AG.group_id = agstates.group_id
WHERE	ag.name = @AvailabilityGroupName;

IF OBJECT_ID('tempdb..#AGScript') IS NOT NULL DROP TABLE #AGScript;
CREATE TABLE #AGScript([ID] [int] NOT NULL IDENTITY(1,1),ServerName sysname NOT NULL,Script NVARCHAR(MAX)NOT NULL,PrintNote NVARCHAR(2048)NULL);


IF EXISTS (SELECT TOP 1 1 FROM	sys.databases WHERE	name = @DatabaseName AND recovery_model !=  1)
BEGIN
	INSERT #AGScript ( ServerName, Script,PrintNote )
	SELECT @PrimaryReplica,CONCAT(N' ALTER DATABASE ',QUOTENAME(@DatabaseName),' SET RECOVERY FULL WITH NO_WAIT;'),CONCAT(@PrimaryReplica,'::Make DB ',@DatabaseName,' recovery to FULL')
END

INSERT #AGScript ( ServerName, Script,PrintNote )
SELECT @PrimaryReplica,CONCAT(N'BACKUP DATABASE ',QUOTENAME(@DatabaseName),' TO  DISK = N''',@SharePath,@DatabaseName,'.bak'' WITH FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5;'),CONCAT(@PrimaryReplica,'::Backup(F) DB ',@DatabaseName)
UNION ALL SELECT @PrimaryReplica,CONCAT(N'ALTER AVAILABILITY GROUP ',QUOTENAME(@AvailabilityGroupName),' ADD DATABASE ',QUOTENAME(@DatabaseName),';'),CONCAT(@PrimaryReplica,'::Add DB ',@DatabaseName,' to Availability Group ',@AvailabilityGroupName)
UNION ALL SELECT @PrimaryReplica,CONCAT(N'BACKUP LOG ',QUOTENAME(@DatabaseName),' TO  DISK = N''',@SharePath,@DatabaseName,@Time,'.trn'' WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5;'),CONCAT(@PrimaryReplica,'::Backup(L) DB ',@DatabaseName)
;
--Script for Secondery
INSERT #AGScript ( ServerName, Script,PrintNote )
SELECT	AR.replica_server_name,CONCAT(N'RESTORE DATABASE ',QUOTENAME(@DatabaseName),' FROM  DISK = N''',@SharePath,@DatabaseName,'.bak'' WITH  NORECOVERY,  NOUNLOAD,  STATS = 5;'),CONCAT(AR.replica_server_name,'::Restore(F) DB ',@DatabaseName)
FROM	master.sys.availability_groups AS AG
		LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states AS agstates ON AG.group_id = agstates.group_id
		INNER JOIN master.sys.availability_replicas AS AR ON AG.group_id = AR.group_id
WHERE	ag.name = @AvailabilityGroupName
		AND AR.replica_server_name != SERVERPROPERTY('ComputerNamePhysicalNetBIOS')
UNION ALL SELECT	AR.replica_server_name,CONCAT(N'RESTORE LOG ',QUOTENAME(@DatabaseName),' FROM  DISK = N''',@SharePath,@DatabaseName,@Time,'.trn'' WITH  NORECOVERY,  NOUNLOAD,  STATS = 5;'),CONCAT(AR.replica_server_name,'::Restore(L) DB ',@DatabaseName)
FROM	master.sys.availability_groups AS AG
		LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states AS agstates ON AG.group_id = agstates.group_id
		INNER JOIN master.sys.availability_replicas AS AR ON AG.group_id = AR.group_id
WHERE	ag.name = @AvailabilityGroupName
		AND AR.replica_server_name != SERVERPROPERTY('ComputerNamePhysicalNetBIOS')
UNION ALL SELECT	AR.replica_server_name,CONCAT(N'PRINT ''Wait for the replica to start communicating''; 
begin try
declare @conn bit; 
declare @count int; 
declare @replica_id uniqueidentifier;
declare @group_id uniqueidentifier; 
set @conn = 0;
set @count = 30; /* wait for 5 minutes */ 

if (serverproperty(''IsHadrEnabled'') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty(''ComputerNamePhysicalNetBIOS'') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0) 
begin 
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N''',QUOTENAME(@AvailabilityGroupName),'''; 
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id; 
	while @conn <> 1 and @count > 0 
	begin 
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1); 
		if @conn = 1 
		begin 
			break; 
		end; 
		waitfor delay ''00:00:10''; 
		set @count = @count - 1; 
	end; 
end; 
end try 
begin catch 
	
end catch'),CONCAT(AR.replica_server_name,'::Connect DB ',@DatabaseName)
FROM	master.sys.availability_groups AS AG
		LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states AS agstates ON AG.group_id = agstates.group_id
		INNER JOIN master.sys.availability_replicas AS AR ON AG.group_id = AR.group_id
WHERE	ag.name = @AvailabilityGroupName
		AND AR.replica_server_name != SERVERPROPERTY('ComputerNamePhysicalNetBIOS')		
UNION ALL SELECT	AR.replica_server_name,CONCAT(N'ALTER DATABASE ',QUOTENAME(@DatabaseName),' SET HADR AVAILABILITY GROUP = ',QUOTENAME(@AvailabilityGroupName),';'),CONCAT(AR.replica_server_name,'::Join DB ',@DatabaseName)
FROM	master.sys.availability_groups AS AG
		LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states AS agstates ON AG.group_id = agstates.group_id
		INNER JOIN master.sys.availability_replicas AS AR ON AG.group_id = AR.group_id
WHERE	ag.name = @AvailabilityGroupName
		AND AR.replica_server_name != SERVERPROPERTY('ComputerNamePhysicalNetBIOS')		
;

IF EXISTS ( SELECT TOP 1 1 FROM master.sys.configurations C WHERE C.name = 'show advanced options' AND C.value = 0 )
BEGIN
	RAISERROR ('Turn on "show advanced options"',0,1) WITH NOWAIT;
	EXEC master.sys.sp_configure 'show advanced options', 1;
	RECONFIGURE WITH OVERRIDE;
	SET @showadvanced = 1;
END
IF EXISTS ( SELECT TOP 1 1 FROM master.sys.configurations C WHERE   C.name = 'xp_cmdshell' AND C.value = 0 )
BEGIN
	RAISERROR ('Turn on "xp_cmdshell"',0,1) WITH NOWAIT;
	EXEC master.sys.sp_configure 'xp_cmdshell', 1;
	RECONFIGURE WITH OVERRIDE;
	SET @cmdshell = 1;
	
END
				
		
		DECLARE cuAG CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
		SELECT	'sqlcmd -S "' + ServerName + '" -Q "' + REPLACE(Script,'
',' ') +'"' ,PrintNote
		FROM	#AGScript
		ORDER BY ID;
		
		OPEN cuAG
		
		FETCH NEXT FROM cuAG INTO @cmdForShell,@PrintNote;
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
		    DELETE FROM @cmdOutput;
			PRINT '-------------------------------'
			PRINT @PrintNote;
			PRINT @cmdForShell; 
			INSERT @cmdOutput 
			EXEC xp_cmdshell @cmdForShell;

			SET @PrintNote = N'';
			SELECT	@PrintNote += line + @CRLF	
			FROM	@cmdOutput
			WHERE	line IS NOT NULL;
			IF @PrintNote LIKE '%Msg%' 
			BEGIN
				RAISERROR(@PrintNote,16,1);
				GOTO Cleanup;
			END
			ELSE PRINT @PrintNote;
		    FETCH NEXT FROM cuAG INTO @cmdForShell,@PrintNote;
		END
		

Cleanup:
	CLOSE cuAG
	DEALLOCATE cuAG
	DROP TABLE #AGScript;
	IF @cmdshell = 1
    BEGIN
		RAISERROR ('Turn off "xp_cmdshell"',0,1) WITH NOWAIT;
        EXEC master.sys.sp_configure 'xp_cmdshell', 0;
        RECONFIGURE WITH OVERRIDE;
    END;
    IF @showadvanced = 1
    BEGIN
		RAISERROR ('Turn off "show advanced options"',0,1) WITH NOWAIT;
        EXEC master.sys.sp_configure 'show advanced options', 0;
        RECONFIGURE WITH OVERRIDE;
    END;
END