-- =============================================
-- Author:		Sharon Rimer
-- Create date: 12/01/2016
-- Update date: 19/01/2016 - Sharon SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- Description:	0 - Only Job Info
--				1 - Job + Catalog
--				2 - Job + Catalog Detail
--				3 - Job + Catalog Detail (Only imported columns)
--				4 - Job + Catalog Detail + Packege Detail(without error msg) 
--				5 - Job + Catalog Detail + Packege Detail (All msg types)
-- =============================================
CREATE PROCEDURE [SSIS].[ups_GetJobExecuteInfo]
	@job_name  VARCHAR(256) = 'Daily ETL',
	@Mode int = 0,
	@Date DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF @Mode IS NULL SET @Mode = 0;
    DECLARE @job_id UNIQUEIDENTIFIER 
	DECLARE @Run_id UNIQUEIDENTIFIER = NEWID();
	DECLARE @JOBstart_execution_date DATETIME,
			@JOBstop_execution_date DATETIME,
			@Error nvarchar(2048)
    --search for job_id if none was provided
    SELECT  @job_id = COALESCE(@job_id,job_id)
    FROM    msdb.dbo.sysjobs 
    WHERE   name like '%' + @job_name + '%';

	IF @Date IS NULL
	BEGIN
		SELECT  TOP 1 @JOBstart_execution_date = t1.start_execution_date
				,@JOBstop_execution_date = t1.stop_execution_date
		FROM    msdb.dbo.sysjobactivity t1
		WHERE   t1.job_id = COALESCE(@job_id,t1.job_id)--If no job_id detected, return last run job
		ORDER  BY   last_executed_step_date DESC;
    END
	ELSE
	BEGIN
    	SELECT  @JOBstart_execution_date = min(msdb.dbo.agent_datetime(run_date, run_time))
				,@JOBstop_execution_date = MAX(msdb.dbo.agent_datetime(run_date, run_time))
		FROM    msdb.dbo.sysjobhistory  t1
		WHERE   t1.job_id = COALESCE(@job_id,t1.job_id)--If no job_id detected, return last run job
				AND CONVERT(date, RTRIM(run_date)) = @Date;
    END


	--Dynamic SQL
	DECLARE @SELECT NVARCHAR(MAX) = N'';
	DECLARE @FROM NVARCHAR(MAX) = N'';
	DECLARE @WHERE NVARCHAR(MAX) = N'';

	SELECT @SELECT = N'SELECT  t1.name as JobName
		,t2.step_id as StepID
		,CASE WHEN t2.step_name = ''(Job outcome)'' THEN ''**** Total Status ****'' else t2.step_name end as StepName,

		DT.FullDateTime,
		' + IIF(@Mode = 0 ,N'dt.JobDurationHHMMSS',N't2.run_duration') + '   [JobDuration],
		' + IIF(@Mode != 0 ,N'CAT.[PKG_RunDuration],',N'') 
		  + IIF(@Mode IN (4,5)  ,N'EM.[Elapsed time],EM.message_time,   EM.message_desc,   EM.message_source_desc,   EM.message,',N'') + 
		N'
		CASE t2.run_status WHEN 0 THEN ''Failed''
							WHEN 1 THEN ''Succeeded'' 
							WHEN 2 THEN ''Retry'' 
							WHEN 3 THEN ''Cancelled'' 
							WHEN 4 THEN ''In Progress'' 
							END as ExecutionStatus
		,t2.message as MessageGenerated  
		' + IIF(@Mode != 0 ,N',CAT.package_name,
		CONVERT(DATETIME,CAT.start_time) [PKG_StartTime],
		CONVERT(DATETIME,CAT.end_time ) [PKG_EndTime]',N'') + 
		IIF(@Mode = 2,N'
		,CAT.execution_id,
   CAT.folder_name,
   CAT.project_name,
   CAT.package_name,
   CAT.environment_name,
   CAT.project_lsn
,   CAT.executed_as_name
,   CAT.use32bitruntime
,   CAT.created_time
,   CAT.start_time
,   CAT.end_time
,   CAT.caller_name
,   CAT.stopped_by_name
,   CAT.server_name
,   CAT.total_physical_memory_kb
,   CAT.available_physical_memory_kb
,   CAT.total_page_file_kb
,   CAT.available_page_file_kb
,   CAT.cpu_count
,   CAT.name
,   CAT.last_deployed_time
,   CAT.validation_status
,   CAT.package_id
,   CAT.[PKG_Name]
,   CAT.version_major
,   CAT.version_minor
,   CAT.version_build
,   CAT.version_comments
,   CAT.[PKG_ValidationStatus]
',N'') + ',@Run_id [RunID]'
			--,CAT.* --'load_stg.dtsx' 'load_stg.dtsx'
    SELECT @FROM = N'
FROM    msdb.dbo.sysjobs t1
			INNER JOIN    msdb.dbo.sysjobhistory t2 ON t1.job_id = t2.job_id 
			CROSS APPLY (SELECT TOP 1 CONVERT(CHAR(10), CAST(STR(t2.run_date,8, 0) AS DATETIME), 121) as RunDate,
            STUFF(STUFF(RIGHT(''000000'' + CAST ( t2.run_time AS VARCHAR(6 ) ) ,6),5,0,'':''),3,0,'':'') as RunTime,
			CONVERT(CHAR(10), CAST(STR(t2.run_date,8, 0) AS DATETIME), 121)  + '' '' + STUFF(STUFF(RIGHT(''000000'' + CAST ( t2.run_time AS VARCHAR(6 ) ) ,6),5,0,'':''),3,0,'':'') + ''.000'' FullDateTime ,
			JobDurationHHMMSS = STUFF(STUFF(REPLACE(STR(t2.run_duration,7,0),'' '',''0''),4,0,'':''),7,0,'':'')
			)DT  
			' + IIF(@Mode != 0 ,N'outer apply (SELECT TOP 1
    E.execution_id,
   E.folder_name,
   E.project_name,
   E.package_name,
   E.environment_name,
   E.project_lsn
,   E.executed_as_name
,   E.use32bitruntime
,   E.created_time
,   E.start_time
,   E.end_time
,   E.caller_name
,   E.stopped_by_name
,   E.server_name
,   E.total_physical_memory_kb
,   E.available_physical_memory_kb
,   E.total_page_file_kb
,   E.available_page_file_kb
,   E.cpu_count
,   F.name
,   P.last_deployed_time
,   P.validation_status
,   PKG.package_id
,   PKG.name [PKG_Name]
,   PKG.version_major
,   PKG.version_minor
,   PKG.version_build
,   PKG.version_comments
,   PKG.validation_status [PKG_ValidationStatus]
,	DATEDIFF(MINUTE,E.start_time,E.end_time)[PKG_RunDuration]
FROM	SSISDB.catalog.executions AS E
		INNER JOIN ssisdb.catalog.folders AS F ON F.name = E.folder_name
		INNER JOIN SSISDB.catalog.projects AS P ON P.folder_id = F.folder_id
                                 AND P.name = E.project_name
		INNER JOIN SSISDB.catalog.packages AS PKG ON PKG.project_id = P.project_id
                                   AND PKG.name = E.package_name
WHERE	convert(Datetime,start_time) >= DT.FullDateTime--DATEADD(MINUTE,-5,DT.FullDateTime)
		AND (LOWER(E.package_name) = LOWER(t2.step_name+ ''.dtsx'') COLLATE DATABASE_DEFAULT 
			 OR LOWER(E.package_name) = LOWER(replace(t2.step_name,'' '',''_'')+ ''.dtsx'') COLLATE DATABASE_DEFAULT)
ORDER BY E.execution_id ASC
)Cat',N'') 
 SELECT @FROM += IIF(@Mode IN (4,5),N'

OUTER APPLY (SELECT TOP 1 O.operation_id
			 FROM	SSISDB.catalog.event_messages em
					INNER JOIN SSISDB.catalog.operations o on em.operation_id=o.operation_id
			WHERE	o.object_name = ''OP_ETL''
					AND EM.package_name = CAT.package_name
			ORDER BY O.operation_id DESC
			)OID
		OUTER APPLY (SELECT
   CONVERT(DATETIME,OM.message_time) message_time
,   EM.message_desc
,   D.message_source_desc
,   OM.message
,SUBSTRING(OM.message,charindex(''Elapsed time:'',OM.message) + 13,12)[Elapsed time]
FROM
    SSISDB.catalog.operation_messages AS OM
    INNER JOIN
        SSISDB.catalog.operations AS O
        ON O.operation_id = OM.operation_id
    INNER JOIN
    (
        VALUES
            (-1,''Unknown'')
        ,   (120,''Error'')
        ,   (110,''Warning'')
        ,   (70,''Information'')
        ,   (10,''Pre-validate'')
        ,   (20,''Post-validate'')
        ,   (30,''Pre-execute'')
        ,   (40,''Post-execute'')
        ,   (60,''Progress'')
        ,   (50,''StatusChange'')
        ,   (100,''QueryCancel'')
        ,   (130,''TaskFailed'')
        ,   (90,''Diagnostic'')
        ,   (200,''Custom'')
        ,   (140,''DiagnosticEx Whenever an Execute Package task executes a child package, it logs this event. The event message consists of the parameter values passed to child packages.  The value of the message column for DiagnosticEx is XML text.'')
        ,   (400,''NonDiagnostic'')
        ,   (80,''VariableValueChanged'')
    ) EM (message_type, message_desc) ON EM.message_type = OM.message_type
    INNER JOIN
    (
        VALUES
            (10,''Entry APIs, such as T-SQL and CLR Stored procedures'')
        ,   (20,''External process used to run package (ISServerExec.exe)'')
        ,   (30,''Package-level objects'')
        ,   (40,''Control Flow tasks'')
        ,   (50,''Control Flow containers'')
        ,   (60,''Data Flow task'')
    ) D (message_source_type, message_source_desc) ON D.message_source_type = OM.message_source_type
WHERE
    OM.operation_id =  OID.operation_id ' + IIF(@Mode = 4 , N'AND OM.message_type = 40' , N'' ) +N')EM
	',N'')
	SELECT @WHERE = N'
WHERE	--Filter on the most recent job_id
        t1.job_id = @job_id 
        --Filter out job steps that do not fall between start_execution_date and stop_execution_date
        AND DT.FullDateTime BETWEEN @JOBstart_execution_date AND @JOBstop_execution_date
ORDER BY t2.step_id ASC'+ IIF(@Mode IN (4,5),N',EM.message_time ASC',N'')

	SELECT @SELECT += @FROM + @WHERE;
	
	begin try
		EXEC sp_executesql @SELECT ,N'@job_id UNIQUEIDENTIFIER ,@JOBstart_execution_date DATETIME,@JOBstop_execution_date DATETIME,@Run_id UNIQUEIDENTIFIER',@job_id = @job_id,
		@JOBstart_execution_date = @JOBstart_execution_date, @JOBstop_execution_date = @JOBstop_execution_date,@Run_id = @Run_id;
		PRINT @SELECT
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_MESSAGE()
		EXEC [dbo].[PrintMax] @SELECT;
		RAISERROR(@Error,16,1);
	END CATCH
	
END