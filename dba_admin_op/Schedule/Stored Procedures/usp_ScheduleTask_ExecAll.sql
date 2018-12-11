-- =============================================
-- Author:      Sharon
-- Create date: 04/05/2017
-- Update date: 
-- Description: Run on time
-- =============================================
CREATE PROCEDURE [Schedule].[usp_ScheduleTask_ExecAll]
AS 
BEGIN  
    SET NOCOUNT ON;

    DECLARE @JobRequest TABLE (JobNumber INT NOT NULL);
	DECLARE @JobNumber INT;
    DECLARE @now TIME = CONVERT(TIME,GETDATE());
	DECLARE @MessageBody XML;
    
	;WITH hadr AS (
		SELECT DISTINCT
				dbcs.database_name AS DatabaseName,IIF(ISNULL(arstates.role, 3) = 1,ISNULL(dbcs.is_database_joined, 0),0) IsAccessable,AG.name
		FROM    master.sys.availability_groups AS AG
				LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states AS agstates ON AG.group_id = agstates.group_id
				INNER JOIN master.sys.availability_replicas AS AR ON AG.group_id = AR.group_id
				INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates ON AR.replica_id = arstates.replica_id
																	  AND arstates.is_local = 1
				INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs ON arstates.replica_id = dbcs.replica_id
				LEFT OUTER JOIN master.sys.dm_hadr_database_replica_states AS dbrs ON dbcs.replica_id = dbrs.replica_id
                                                              AND dbcs.group_database_id = dbrs.group_database_id
	), DB AS (
		SELECT	D.name ,H.IsAccessable ,H.name AGname
		FROM	sys.databases D
				LEFT JOIN hadr H ON D.name = H.DatabaseName 
		WHERE	ISNULL(H.IsAccessable,1) = 1
				AND D.[state] = 0
	)
	INSERT @JobRequest
    SELECT  ES.ID
    FROM    [Schedule].[Schedule_Configuration]ES
            INNER JOIN DB D ON D.name = ES.[Database]
    WHERE   ES.[RunDailyHour] = DATEDIFF(hour, '00:00:00', @now)
            AND ISNULL(ES.Server,@@SERVERNAME) = @@SERVERNAME
            AND ES.IsActive = 1
	UNION ALL
    -- Run interval SPs
    SELECT  ES.ID
    FROM    [Schedule].[Schedule_Configuration] ES
            INNER JOIN DB D ON D.name = ES.[Database]
    WHERE   DATEDIFF(minute, '00:00:00', @now) % ES.[RunInterval] < 3 -- עד הפרש של 3 דקות
            AND ISNULL(ES.Server,@@SERVERNAME) = @@SERVERNAME
            AND ES.IsActive = 1;

	IF EXISTS (SELECT TOP 1 1 FROM @JobRequest)
	BEGIN
	    /* declare variables */
	    
	    DECLARE cuJobs CURSOR LOCAL FAST_FORWARD READ_ONLY FOR SELECT JobNumber FROM @JobRequest
	    
	    OPEN cuJobs
	    
	    FETCH NEXT FROM cuJobs INTO @JobNumber
	    
	    WHILE @@FETCH_STATUS = 0
	    BEGIN
	        
			SELECT @MessageBody = CONCAT('<JobRequest><JobNumber>',@JobNumber,'</JobNumber></JobRequest>');
			EXECUTE [Schedule].usp_SendBrokerMessage @MessageBody;
	        FETCH NEXT FROM cuJobs INTO @JobNumber
	    END
	    
	    CLOSE cuJobs
	    DEALLOCATE cuJobs
	END
       
    
END