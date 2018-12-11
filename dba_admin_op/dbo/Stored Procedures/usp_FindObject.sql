-- =============================================
-- Author:		Sharon
-- Create date: 12/10/2014
-- Description:	FindObject
-- =============================================
CREATE PROCEDURE [dbo].[usp_FindObject]
	@Text nvarchar(4000),
	@DatabaseName sysname,
	@Table BIT = 1,
	@Column BIT = 1,
	@View BIT = 1,
	@Function BIT = 1,
	@Procedure BIT = 1,
	@Trigger BIT = 1,
	@Constreint BIT = 1,
	@Job BIT = 0,
	@ReportServer BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

    IF @Text IS NULL 
		RAISERROR ('Insert text to look for!',16,1);
	
	DECLARE @cmd NVARCHAR(max) = N'';

	IF IIF(@Table IS NULL,0,@Table) + IIF(@Column IS NULL,0,@Column) +IIF(@View IS NULL,0,@View) +IIF(@Function IS NULL,0,@Function) 
	+IIF(@Procedure IS NULL,0,@Procedure) +IIF(@Trigger IS NULL,0,@Trigger) +IIF(@Constreint IS NULL,0,@Constreint)  > 0
	BEGIN
	    IF NOT EXISTS (SELECT TOP 1 1 FROM sys.databases WHERE name = @DatabaseName)
		BEGIN
			RAISERROR ('Insert valid DB name',16,1);
			RETURN -1;
		END
		ELSE
		BEGIN
		    
	

	CREATE TABLE #Result ([Object Schema] sysname NULL,
						  [Object Name] sysname NULL,
						  [Object Type] sysname NULL,
						  [TEXT Location] NVARCHAR(max) NULL,
						  [Position] NVARCHAR(1000));
	
	-- Table names
	IF @Table = 1
	BEGIN
		SET @cmd = CONCAT(N'INSERT #Result
SELECT TABLE_SCHEMA  AS [Object Schema]
		,TABLE_NAME    AS [Object Name]
		,TABLE_TYPE    AS [Object Type]
		,''Table Name''  AS [TEXT Location]
		,NULL
FROM  ',@DatabaseName,'.INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE ''%''+@Text+''%''')
		EXEC sp_executesql @cmd ,N'@Text nvarchar(4000)',@Text = @Text
	END

	--Column names| computed_columns
	IF @Column = 1
	BEGIN
		SET @cmd = CONCAT(N'INSERT #Result
SELECT	TABLE_SCHEMA   AS [Object Schema]
		,TABLE_NAME   AS [Object Name]
		,''COLUMN''      AS [Object Type]
		,COLUMN_NAME AS [TEXT Location]
		,NULL
FROM  ',@DatabaseName,'.INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE ''%''+@Text+''%''
UNION ALL 

SELECT	OBJECT_SCHEMA_NAME(o.object_id,DB_ID(''',@DatabaseName,''')) AS [Object Schema]
		,o.name       AS [Object Name]
		,o.type_desc       AS [Object Type]
		,C.definition AS [TEXT Location]
		,NULL
FROM	',@DatabaseName,'.SYS.computed_columns C
		INNER JOIN ',@DatabaseName,'.sys.objects  o ON C.object_id=o.object_id
WHERE	C.definition Like ''%''+@Text+''%''
')
		EXEC sp_executesql @cmd ,N'@Text nvarchar(4000)',@Text = @Text
	END
	
	--PROCEDURE
	IF @Procedure = 1
	BEGIN
		SET @cmd = CONCAT(N'INSERT #Result
SELECT	OBJECT_SCHEMA_NAME(o.object_id,DB_ID(''',@DatabaseName,''')) AS [Object Schema]
		,o.name       AS [Object Name]
		,''PROCEDURE'' AS [Object Type]
		,m.definition AS [TEXT Location]
		,SUBSTRING(m.definition,PATINDEX(''%''+@Text+''%'',m.definition),100)
FROM	',@DatabaseName,'.sys.sql_modules m 
		INNER JOIN ',@DatabaseName,'.sys.objects  o ON m.object_id=o.object_id
WHERE	m.definition Like ''%''+@Text+''%''
		and o.type = ''P''')
		EXEC sp_executesql @cmd ,N'@Text nvarchar(4000)',@Text = @Text
	END


	-- FUNCTION
	IF @Function = 1
	BEGIN
		SET @cmd = CONCAT(N'INSERT #Result
SELECT	OBJECT_SCHEMA_NAME(o.object_id,DB_ID(''',@DatabaseName,''')) AS [Object Schema]
		,o.name       AS [Object Name]
		,''FUNCTION('' + o.type + '')'' COLLATE SQL_Latin1_General_CP1_CI_AS AS [Object Type]
		,m.definition AS [TEXT Location]
		,SUBSTRING(m.definition,PATINDEX(''%''+@Text+''%'',m.definition),100)
FROM	',@DatabaseName,'.sys.sql_modules m 
		INNER JOIN ',@DatabaseName,'.sys.objects  o ON m.object_id=o.object_id
WHERE	m.definition Like ''%''+@Text+''%''
		and o.type in (''FN'',''AF'',''FS'',''FT'',''IF'',''TF'')')
		EXEC sp_executesql @cmd ,N'@Text nvarchar(4000)',@Text = @Text
	END
	-- Trigger
	IF @Trigger = 1
	BEGIN
		SET @cmd = CONCAT(N'INSERT #Result
SELECT	OBJECT_SCHEMA_NAME(o.object_id,DB_ID(''',@DatabaseName,''')) AS [Object Schema]
		,o.name       AS [Object Name]
		,''FUNCTION('' + o.type + '')'' COLLATE SQL_Latin1_General_CP1_CI_AS AS [Object Type]
		,m.definition AS [TEXT Location]
		,SUBSTRING(m.definition,PATINDEX(''%''+@Text+''%'',m.definition),100)
FROM	',@DatabaseName,'.sys.sql_modules m 
		INNER JOIN ',@DatabaseName,'.sys.objects  o ON m.object_id = o.object_id
WHERE	m.definition Like ''%''+@Text+''%''
		and o.type = ''TR''')
		EXEC sp_executesql @cmd ,N'@Text nvarchar(4000)',@Text = @Text
	END
	--View
	IF @View = 1
	BEGIN
		SET @cmd = CONCAT(N'INSERT #Result
SELECT	OBJECT_SCHEMA_NAME(o.object_id,DB_ID(''',@DatabaseName,''')) AS [Object Schema]
		,o.name       AS [Object Name]
		,o.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS AS [Object Type]
		,m.definition AS [TEXT Location]
		,SUBSTRING(m.definition,PATINDEX(''%''+@Text+''%'',m.definition),100)
FROM	',@DatabaseName,'.sys.sql_modules m 
		INNER JOIN ',@DatabaseName,'.sys.objects  o ON m.object_id = o.object_id
WHERE	m.definition Like ''%''+@Text+''%''
		and o.type = ''v''')
		EXEC sp_executesql @cmd ,N'@Text nvarchar(4000)',@Text = @Text
	END
	
	--default_constraints| check_constraints
	IF @Constreint = 1
	BEGIN
		SET @cmd = CONCAT(N'INSERT #Result
SELECT	OBJECT_SCHEMA_NAME(o.object_id,DB_ID(''',@DatabaseName,''')) AS [Object Schema]
		,o.name       AS [Object Name]
		,o.type_desc       AS [Object Type]
		,D.definition AS [TEXT Location]
		,SUBSTRING(D.definition,PATINDEX(''%''+@Text+''%'',D.definition),100)
FROM	',@DatabaseName,'.SYS.default_constraints D
		INNER JOIN ',@DatabaseName,'.sys.objects  o ON D.object_id = o.object_id
WHERE	D.definition Like ''%''+@Text+''%''
UNION ALL 
SELECT	OBJECT_SCHEMA_NAME(o.object_id,DB_ID(''',@DatabaseName,''')) AS [Object Schema]
		,o.name       AS [Object Name]
		,o.type_desc       AS [Object Type]
		,C.definition AS [TEXT Location]
		,SUBSTRING(D.definition,PATINDEX(''%''+@Text+''%'',D.definition),100)
FROM	',@DatabaseName,'.SYS.check_constraints C
		INNER JOIN ',@DatabaseName,'.sys.objects  o ON C.object_id = o.object_id
WHERE	C.definition Like ''%''+@Text+''%''')
		EXEC sp_executesql @cmd ,N'@Text nvarchar(4000)',@Text = @Text
	END

	SELECT	* 
	FROM	#Result

	DROP TABLE #Result;
	
		END
	END
-- Job
IF @Job = 1
BEGIN
	DECLARE @PreviewTextSize INT = 100

	SELECT  'Job Steps' As SearchType,
			j.[Name] AS [Job Name] ,
			s.Step_Id AS [Step #] ,
			REPLACE(REPLACE(SUBSTRING(s.Command,
										CHARINDEX(@Text, s.Command)
										- @PreviewTextSize / 2, @PreviewTextSize),
							CHAR(13) + CHAR(10), ''), @Text,
					'***' + @Text + '***') AS Command
	FROM    MSDB.dbo.sysJobs j
			INNER JOIN MSDB.dbo.sysJobSteps s ON j.Job_Id = s.Job_Id
	WHERE   s.Command LIKE '%' + @Text + '%';
END
-- SSRS
IF @ReportServer = 1
BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM SYS.databases WHERE name = 'ReportServer')
	BEGIN
	WITH    cte
	          AS (
			  --gets the RDL; note the double convert.
	               SELECT   [path] ,
	                        [name] AS Report_Name ,
	                        CONVERT(XML, CONVERT(VARBINARY(MAX), content)) AS rdl
	               FROM     ReportServer.dbo.catalog
	             )
	    SELECT  LEFT([Path], LEN([path]) - CHARINDEX('/', REVERSE([Path])) + 1) AS Report_Path ,
	            Report_Name ,
	            T1.N.value('@Name', 'nvarchar(128)') AS DataSetName ,
	            T2.N.value('(*:DataSourceName/text())[1]', 'nvarchar(128)') AS DataSourceName ,
	            ISNULL(T2.N.value('(*:CommandType/text())[1]', 'nvarchar(128)'),
	                   'T-SQL') AS CommandType ,
	            T2.N.value('(*:CommandText/text())[1]', 'nvarchar(max)') AS CommandText
		INTO	#SSRS
	    FROM    cte AS T
	            CROSS APPLY T.rdl.nodes('/*:Report/*:DataSets/*:DataSet') AS T1 ( N )
	            CROSS APPLY T1.N.nodes('*:Query') AS T2 ( N )
	    ORDER BY Report_Path ,
	            Report_Name ,
	            DataSetName ,
	            DataSourceName ,
	            CommandType ,
	            CommandText;

		SELECT	* 
		FROM	#SSRS
		WHERE	CommandText LIKE '%' + @Text  + '%';
	END
END
END



