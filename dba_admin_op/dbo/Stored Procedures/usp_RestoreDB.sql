-- =============================================
-- Author:      Sharon Rimer
-- Create date: 13/01/2016
-- Description: Restore Backup file to server location
-- =============================================
CREATE PROCEDURE dbo.usp_RestoreDB
    @DBNameTo sysname,
    @BackupFilePath NVARCHAR(1000),
    @KillActiveSession BIT = 0,
    @Exec BIT = 0,
    @RestoreDataPath NVARCHAR(1000) = NULL,
    @RestoreLogPath NVARCHAR(1000) = NULL,
	@NORECOVERY BIT = 0
AS
BEGIN 
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @CRLF VARCHAR(100)= '
',
        @DBLogFilename NVARCHAR(1500)= N'',
        @DBDataPath NVARCHAR(1500)= N'',
        @DBLogPath NVARCHAR(1500)= N'',
        @ExecSQL NVARCHAR(MAX)= N'',
        @MoveSQL NVARCHAR(MAX)= N'',
        @REPLACE NVARCHAR(50) = N'',
        @v_strTEMP NVARCHAR(1000)= N'',
        @v_strListSQL NVARCHAR(4000)= N'',
        @v_strServerVersion NVARCHAR(20)= N'',
        @DBLogicalname VARCHAR(1000)= '',
        @RemoveAvalibilityGroup NVARCHAR(MAX),
        @AvalibilityGroup sysname,
        @showadvanced INT  = 0,
        @cmdshell INT = 0,
        @cmdForShell VARCHAR(8000);
    DECLARE @cmdOutput TABLE (line NVARCHAR(255));
              

    IF EXISTS ( SELECT TOP 1 1
                FROM    master.sys.databases
                WHERE   name = @DBNameTo )
    BEGIN
        SET @REPLACE = N', REPLACE';
        IF EXISTS ( SELECT TOP 1 1
                    FROM    master.sys.databases
                    WHERE   name = @DBNameTo
                            AND group_database_id IS NOT NULL )
        BEGIN
            SELECT  @RemoveAvalibilityGroup = N'ALTER AVAILABILITY GROUP ['
                    + AG.name + N'] REMOVE DATABASE ' + QUOTENAME(@DBNameTo)
                    + N';' + @CRLF,
                    @AvalibilityGroup = AG.name
            FROM    master.sys.availability_groups AS AG
                    LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states
                    AS agstates ON AG.group_id = agstates.group_id
                    INNER JOIN master.sys.availability_replicas AS AR ON AG.group_id = AR.group_id
                    INNER JOIN master.sys.dm_hadr_availability_replica_states
                    AS arstates ON AR.replica_id = arstates.replica_id
                                   AND arstates.is_local = 1
                    INNER JOIN master.sys.dm_hadr_database_replica_cluster_states
                    AS dbcs ON arstates.replica_id = dbcs.replica_id
            WHERE   dbcs.database_name = @DBNameTo;

            SELECT  @cmdForShell = 'sqlcmd -S "' + CN.replica_server_name
                    + '" -D "master" -Q "RESTORE DATABASE ' + @DBNameTo
                    + ' WITH RECOVERY; DROP DATABASE ' + @DBNameTo + ';"'
            FROM    sys.dm_hadr_availability_replica_cluster_nodes CN
            WHERE   @AvalibilityGroup = CN.group_name
                    AND CN.node_name != SERVERPROPERTY('ComputerNamePhysicalNetBIOS');
        END;
    END;
        
    CREATE TABLE #FILE_LIST
        (LogicalName VARCHAR(500),
         PhysicalName VARCHAR(1000),
         Type VARCHAR(1),
         FileGroupName sysname NULL,
         Size DECIMAL(20, 0),
         MaxSize DECIMAL(25, 0),
         FileID BIGINT,
         CreateLSN DECIMAL(25, 0),
         DropLSN DECIMAL(25, 0),
         UniqueID UNIQUEIDENTIFIER,
         ReadOnlyLSN DECIMAL(25, 0),
         ReadWriteLSN DECIMAL(25, 0),
         BackupSizeInBytes DECIMAL(25, 0),
         SourceBlockSize INT,
         filegroupid INT,
         loggroupguid UNIQUEIDENTIFIER,
         differentialbaseLSN DECIMAL(25, 0),
         differentialbaseGUID UNIQUEIDENTIFIER,
         isreadonly BIT,
         ispresent BIT,
         TDEThumbpr DECIMAL(25, 0));
    IF @RestoreDataPath IS NOT NULL
        AND @RestoreLogPath IS NOT NULL
    BEGIN 
        SET @DBDataPath = @RestoreDataPath;
        SET @DBLogPath = @RestoreLogPath;
    END;
    ELSE
    BEGIN
        SELECT TOP 1
                @DBDataPath = LEFT(physical_name,
                                   LEN(physical_name) + 2 - CHARINDEX('\',
                                                              REVERSE(physical_name))
                                   - 1)
        FROM    master.sys.master_files MF
                INNER JOIN master.sys.databases D ON D.database_id = MF.database_id
        WHERE   D.name = @DBNameTo
                AND MF.type = 0; --Data

        SELECT TOP 1
                @DBLogPath = LEFT(physical_name,
                                  LEN(physical_name) + 2 - CHARINDEX('\',
                                                              REVERSE(physical_name))
                                  - 1)
        FROM    master.sys.master_files MF
                INNER JOIN master.sys.databases D ON D.database_id = MF.database_id
        WHERE   D.name = @DBNameTo
                AND MF.type = 1; --Log
    END;
    SELECT  @v_strServerVersion = CAST(SERVERPROPERTY('PRODUCTVERSION') AS NVARCHAR);
       
    BEGIN TRY
        INSERT  #FILE_LIST
        EXEC ('RESTORE FILELISTONLY FROM DISK = ''' + @BackupFilePath + '''' );
    END TRY
    BEGIN CATCH
        THROW;
        GOTO Cleanup;
    END CATCH;

    SELECT  @DBLogFilename = SUBSTRING(PhysicalName,
                                       LEN(PhysicalName) + 2 - CHARINDEX(N'\',
                                                              REVERSE(PhysicalName)),
                                       CHARINDEX(N'\', REVERSE(PhysicalName)))
    FROM    #FILE_LIST
    WHERE   Type = 'L';
       
       
    SELECT  @DBLogicalname = LogicalName
    FROM    #FILE_LIST
    WHERE   FileID = 1;

    IF @DBLogicalname != @DBNameTo
    BEGIN--REPLACE(LogicalName,@DBLogicalname,@DBNameTo)
        SELECT  @MoveSQL += N' MOVE N''' + LogicalName + ''' TO N'''
                + @DBDataPath + REPLACE(SUBSTRING(PhysicalName,
                                                  LEN(PhysicalName) + 2
                                                  - CHARINDEX(N'\',
                                                              REVERSE(PhysicalName)),
                                                  CHARINDEX('\',
                                                            REVERSE(PhysicalName))),
                                        @DBLogicalname, @DBNameTo) + ''',
'
        FROM    #FILE_LIST
        WHERE   Type = 'D';

        SELECT  @MoveSQL += N' MOVE N''' + LogicalName + ''' TO N'''
                + @DBLogPath + REPLACE(SUBSTRING(PhysicalName,
                                                 LEN(PhysicalName) + 2
                                                 - CHARINDEX('\',
                                                             REVERSE(PhysicalName)),
                                                 CHARINDEX('\',
                                                           REVERSE(PhysicalName))),
                                       @DBLogicalname, @DBNameTo) + ''',
'
        FROM    #FILE_LIST
        WHERE   Type = 'L';

        SELECT  @MoveSQL += N' MOVE N''' + LogicalName + ''' TO N'''
                + REPLACE(SUBSTRING(PhysicalName,
                                    LEN(PhysicalName) + 2 - CHARINDEX('\',
                                                              REVERSE(PhysicalName)),
                                    CHARINDEX('\', REVERSE(PhysicalName))),
                          @DBLogicalname, @DBNameTo) + ''',
'
        FROM    #FILE_LIST
        WHERE   Type NOT IN ('D', 'L');
    END;
    ELSE
    BEGIN
        SELECT  @MoveSQL += N' MOVE N''' + LogicalName + ''' TO N'''
                + @DBDataPath + SUBSTRING(PhysicalName,
                                          LEN(PhysicalName) + 2
                                          - CHARINDEX('\',
                                                      REVERSE(PhysicalName)),
                                          CHARINDEX('\', REVERSE(PhysicalName)))
                + ''',
'
        FROM    #FILE_LIST
        WHERE   Type = 'D';
              
        SELECT  @MoveSQL += ' MOVE N''' + LogicalName + ''' TO N'''
                + @DBLogPath + SUBSTRING(PhysicalName,
                                         LEN(PhysicalName) + 2 - CHARINDEX('\',
                                                              REVERSE(PhysicalName)),
                                         CHARINDEX('\', REVERSE(PhysicalName)))
                + ''',
'
        FROM    #FILE_LIST
        WHERE   Type = 'L';

              
        SELECT  @MoveSQL += N' MOVE N''' + LogicalName + ''' TO N'''
                + SUBSTRING(PhysicalName,
                            LEN(PhysicalName) + 2 - CHARINDEX('\',
                                                              REVERSE(PhysicalName)),
                            CHARINDEX('\', REVERSE(PhysicalName))) + ''',
'
        FROM    #FILE_LIST
        WHERE   Type NOT IN ('D', 'L');
    END;
    IF @KillActiveSession = 1
        AND @Exec = 1
    BEGIN
        PRINT 'Killing active connections to the "' + @DBNameTo + '" database';

              -- Create the sql to kill the active database connections
        SET @ExecSQL = '';
        SELECT  @ExecSQL = @ExecSQL + 'kill ' + CONVERT(CHAR(10), spid) + ' '
        FROM    master.dbo.sysprocesses
        WHERE   DB_NAME(dbid) = @DBNameTo
                AND dbid <> 0
                AND spid <> @@SPID;

        EXEC (@ExecSQL);
    END;

    SELECT  @ExecSQL = N'RESTORE DATABASE ' + QUOTENAME(@DBNameTo) + @CRLF
            + N' FROM DISK = ''' + @BackupFilePath + '''' + @CRLF
            + N' WITH FILE = 1,' + @CRLF + @MoveSQL
			+ CASE WHEN @NORECOVERY = 1 THEN N'NORECOVERY,' ELSE N'' END + @CRLF
            + N' NOREWIND, NOUNLOAD, STATS = 5 ' + @REPLACE;
    BEGIN TRY
        IF @Exec = 1
        BEGIN
            IF @RemoveAvalibilityGroup IS NOT NULL
                EXEC master.sys.sp_executesql
                    @RemoveAvalibilityGroup;
            EXEC master.sys.sp_executesql
                @ExecSQL;
            PRINT 'Bazinga! Finish Restoring successfully!';
            SET @ExecSQL = N'EXEC ' + @DBNameTo
                + '.sys.sp_changedbowner ''sa'''; -- fix ownerships problems after transfer
            EXEC master.sys.sp_executesql
                @ExecSQL;
            PRINT 'Update DB owner to sa.';
            --------------------------------------------------------------------------------------------
            IF @RemoveAvalibilityGroup IS NOT NULL
            BEGIN
                IF EXISTS ( SELECT TOP 1
                                    1
                            FROM    master.sys.configurations C
                            WHERE   C.name = 'show advanced options'
                                    AND C.value = 0 )
                BEGIN
                    RAISERROR ('Turn on "show advanced options"',0,1) WITH NOWAIT;
                    EXEC master.sys.sp_configure
                        'show advanced options',
                        1;
                    RECONFIGURE WITH OVERRIDE;
                    SET @showadvanced = 1;
                END;
                IF EXISTS ( SELECT TOP 1
                                    1
                            FROM    master.sys.configurations C
                            WHERE   C.name = 'xp_cmdshell'
                                    AND C.value = 0 )
                BEGIN
                    RAISERROR ('Turn on "xp_cmdshell"',0,1) WITH NOWAIT;
                    EXEC master.sys.sp_configure
                        'xp_cmdshell',
                        1;
                    RECONFIGURE WITH OVERRIDE;
                    SET @cmdshell = 1;
       
                END;
                INSERT  @cmdOutput
                        EXEC xp_cmdshell
                            @cmdForShell;

                SELECT  *
                FROM    @cmdOutput
                WHERE   line IS NOT NULL;


            END;

        END;
        ELSE
        BEGIN--Print
            IF @RemoveAvalibilityGroup IS NOT NULL
            BEGIN
                PRINT '---------------------------';
                PRINT @RemoveAvalibilityGroup;
            END;
            PRINT '---------------------------';
            PRINT @ExecSQL;
            PRINT '---------------------------';
        END;
    END TRY
    BEGIN CATCH
        THROW;
        GOTO Cleanup;
    END CATCH;

    Cleanup:
    DROP TABLE #FILE_LIST;
    IF @cmdshell = 1
    BEGIN
        RAISERROR ('Turn off "xp_cmdshell"',0,1) WITH NOWAIT;
        EXEC master.sys.sp_configure
            'xp_cmdshell',
            0;
        RECONFIGURE WITH OVERRIDE;
    END;
    IF @showadvanced = 1
    BEGIN
        RAISERROR ('Turn off "show advanced options"',0,1) WITH NOWAIT;
        EXEC master.sys.sp_configure
            'show advanced options',
            0;
        RECONFIGURE WITH OVERRIDE;
    END;
END;