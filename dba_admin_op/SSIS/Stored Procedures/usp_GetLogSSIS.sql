-- =============================================
-- Author:		Sharon
-- Create date: 19/01/2016
-- Description:	@Mode
--				0 :: Single Output 
--				1 :: 2 Output for the screen
--				2 :: Load to external table SSIS.TMP_ReportTotal + SSIS.TMP_ReportDetail for Tobulu Report - last 7 days
--				3 :: Same as 0 without 0 in column [DuarationInMinute]
-- =============================================
CREATE PROCEDURE [SSIS].[usp_GetLogSSIS]
	@RunDate datetime,
	@EndDate datetime,
	@DatabaseName sysname,
	@Mode int = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @CMD NVARCHAR(MAX) = N'';
	IF @Mode IS NULL
	BEGIN
		PRINT '@Mode ::
0 :: Single Output 
1 :: 2 Output for the screen
2 :: Load to external table SSIS.TMP_ReportTotal + SSIS.TMP_ReportDetail for Tobulu Report - last 7 days
3 :: Same as 0 without 0 in column [DuarationInMinute]
		'
		RETURN -1;
	END

	IF @Mode = 2
	BEGIN
		SELECT @EndDate = CONVERT(DATE,GETDATE()) ,@RunDate = FORMAT(DATEADD(DAY,-7,CONVERT(DATE,GETDATE())),'yyyy-MM-dd 23:59:59');
		IF OBJECT_ID('SSIS.TMP_ReportTotal') IS NULL
		CREATE TABLE [SSIS].[TMP_ReportTotal](
			[computer] [nvarchar](128) NOT NULL,
			[Date] [date] NULL,
			[PackageName] [nvarchar](1024) NOT NULL,
			[DuarationInMinute] [int] NULL
		) ON [PRIMARY];
		IF OBJECT_ID('SSIS.TMP_ReportDetail') IS NULL
		CREATE TABLE [SSIS].[TMP_ReportDetail](
			[computer] [nvarchar](128) NOT NULL,
			[Date] [date] NULL,
			[PackageName] [nvarchar](1024) NOT NULL,
			[StepName] [nvarchar](1024) NULL,
			[DuarationInMinute] [int] NULL
		) ON [PRIMARY];

		TRUNCATE TABLE SSIS.TMP_ReportTotal;
		TRUNCATE TABLE SSIS.TMP_ReportDetail;
	END
	SET @CMD = N'
IF OBJECT_ID(''[' + @DatabaseName + '].[dbo].[sysssislog]'') IS NOT NULL
BEGIN
SELECT lo.[id]
		,lo.[computer]
		,' + CASE WHEN @Mode IN (0,3) THEN N'IIF(loO.[source]!=lo.[source],loO.[source] + '' :: '' + lo.[source],lo.[source]) [source]' ELSE N'lo.[source]' END + N' 
		,lo.[starttime]
		,post.[endtime]
		,datediff(MINUTE,lo.[starttime],post.[endtime]) [DuarationInMinute]
		,lo.[message] + ISNULL(post.[message],'''')' + CASE WHEN @Mode IN (0,3) THEN N'+ ISNULL(''Error: '' + Err.[message],'''')' ELSE N'' END + N'[message]
	' + CASE WHEN @Mode IN (1,2) THEN N',post.ID AS [EndID]
	INTO #SSIS_TEMP
		' ELSE N'' END + 
		'
	FROM	' + CASE WHEN @Mode IN (1,2) THEN N'[' + @DatabaseName + '].[dbo].[sysssislog] lo
		INNER JOIN [SSIS].[Package] P ON P.PackageName = lo.[source] COLLATE Hebrew_CI_AS
		' WHEN @Mode IN (0,3) THEN N'[SSIS].[Package] P 
		INNER JOIN [' + @DatabaseName + '].[dbo].[sysssislog] loO ON P.PackageName = loO.[source] COLLATE Hebrew_CI_AS
		INNER JOIN [' + @DatabaseName + '].[dbo].[sysssislog] lo ON loO.executionid = lo.executionid
		OUTER APPLY(SELECT TOP 1 * FROM [' + @DatabaseName + '].[dbo].[sysssislog] p WHERE lo.[source] = p.[source] AND lo.[executionid] = p.[executionid] AND lo.[sourceid] = p.[sourceid] AND p.[event]=''OnError'')Err
		' ELSE N'' END + 
		'OUTER APPLY(SELECT TOP 1 * FROM [' + @DatabaseName + '].[dbo].[sysssislog] p WHERE lo.[source] = p.[source] AND lo.[executionid] = p.[executionid] AND lo.[sourceid] = p.[sourceid] AND p.[event]=''OnPostExecute'')post
	WHERE ' + CASE WHEN @Mode IN (0,3) THEN N'loO.[starttime]' ELSE N'lo.[starttime]' END + N'BETWEEN @RunDate AND ' + IIF(@EndDate IS NULL,N'DATEADD(DAY,1,@RunDate)',N'@EndDate') + N'
		AND lo.[event]=''OnPreExecute''
		' + IIF(@Mode = 3,N'AND datediff(MINUTE,lo.[starttime],post.[endtime]) > 0
		',N'') + N'
		' + CASE WHEN @Mode IN (0,3) THEN N'AND loO.[event]=''OnPreExecute''
	ORDER BY lo.[id] ASC;' ELSE N'' END + 
		'

	' + CASE WHEN @Mode IN (1,2) THEN N'
	' + IIF(@Mode = 2,N'INSERT SSIS.TMP_ReportTotal',N'') + N'
	SELECT [computer],CONVERT(DATE,starttime)[Date],source [PackageName],[DuarationInMinute]' + IIF(@Mode = 2,N',FT.Local_Table',N'') + N'
	FROM #SSIS_TEMP
	ORDER BY 2 ASC;
	' + IIF(@Mode = 2,N'
	INSERT SSIS.TMP_ReportDetail',N'') + N'
	SELECT	T.[computer],CONVERT(DATE,T.starttime)[Date],t.source [PackageName],st.source [StepName],st.[DuarationInMinute]
	FROM	#SSIS_TEMP T
			OUTER APPLY(SELECT	TOP 5  lo.[id]
								,lo.[computer]
								,lo.[source]
								,lo.[starttime]
								,post.[endtime]
								,datediff(MINUTE,lo.[starttime],post.[endtime]) [DuarationInMinute]
								,lo.[message] + ISNULL(post.[message],'''')[message]
								,CONVERT(INT,IIF(ISNUMERIC([dbo].[ufn_Util_clr_RegexReplace](lo.source,''(Pre_load_Table )([\d]+),([\d]+)'',''$2'',1)) = 1,[dbo].[ufn_Util_clr_RegexReplace](lo.source,''(Pre_load_Table )([\d]+),([\d]+)'',''$2'',1),NULL)) [FromTable]
								,CONVERT(INT,IIF(ISNUMERIC([dbo].[ufn_Util_clr_RegexReplace](lo.source,''(Pre_load_Table )([\d]+),([\d]+)'',''$3'',1)) = 1,[dbo].[ufn_Util_clr_RegexReplace](lo.source,''(Pre_load_Table )([\d]+),([\d]+)'',''$3'',1),NULL)) [ToTable]
						FROM	[' + @DatabaseName + '].[dbo].[sysssislog] lo
								OUTER APPLY(select top 1 * from [' + @DatabaseName + '].[dbo].[sysssislog] p where lo.[source] = p.[source] and lo.[executionid] = p.[executionid] and lo.[sourceid] = p.[sourceid]
								and p.[event]=''OnPostExecute'')post
						WHERE	lo.[id] BETWEEN T.ID AND T.EndID
								AND T.source != LO.source
								and lo.[event]=''OnPreExecute''
						ORDER BY 	datediff(MINUTE,lo.[starttime],post.[endtime]) DESC
				) ST
			OUTER APPLY (SELECT [dbo].[ufn_Util_clr_Conc](CONVERT(VARCHAR(5),T.RowNum) + ''::'' + T.[Local_Table])[Local_Table] FROM [OP_STG].[dbo].[tblOracleTables] T WHERE T.RowNum BETWEEN ST.[FromTable] AND ST.[ToTable])FT
			' ELSE N'' END + 
			'
	END
	ELSE
	BEGIN
		PRINT ''Database - ' + @DatabaseName + ' Does not contein table [dbo].[sysssislog]'';
	END'
	if exists(SELECT TOP 1 1 FROM SYS.DATABASES WHERE NAME = @DatabaseName)
	BEGIN
		EXEC sp_executesql @CMD ,N'@RunDate datetime,@EndDate datetime',@RunDate = @RunDate, @EndDate = @EndDate ;
		EXEC [dbo].[PrintMax] @CMD
	END
END