-- =============================================
-- Author:		Sharon
-- Create date: 24/05/2016
-- Description:	Get MP Logs
-- =============================================
CREATE PROCEDURE [_Admin_].[usp_GetMPLogs]
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Silance BIT = 0;

	DECLARE @output nvarchar(max)
	DECLARE @maintplan NVARCHAR(1000)
	DECLARE @MP_Name NVARCHAR(1000)
	IF OBJECT_ID('tempdb..#MPLog') IS NULL 
		CREATE TABLE #MPLog(MP_Name NVARCHAR(1000),FLog NVARCHAR(MAX));
	ELSE
		SET @Silance = 1;

	--Registry
	DECLARE @regvalue varchar(1000)
	DECLARE @regKey varchar(100)
	DECLARE @Path varchar(1000)
	--SQL Versions
	BEGIN
		IF OBJECT_ID('tempdb..#checkversion') IS NOT NULL DROP TABLE #checkversion;
		CREATE TABLE #checkversion (
			version nvarchar(128),
			common_version AS SUBSTRING(version, 1, CHARINDEX('.', version) + 1 ),
			major AS PARSENAME(CONVERT(VARCHAR(32), version), 4),
			minor AS PARSENAME(CONVERT(VARCHAR(32), version), 3),
			build AS PARSENAME(CONVERT(varchar(32), version), 2),
			revision AS PARSENAME(CONVERT(VARCHAR(32), version), 1)
		);

		INSERT INTO #checkversion (version)
		SELECT CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) ;
		SELECT	@regKey = 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL' + major + '.MSSQLServer\SQLServerAgent'
		FROM	#checkversion;
	END

	--Registry
	BEGIN
		EXEC master.dbo.xp_regread @rootkey='HKEY_LOCAL_MACHINE',
    			@key=@regKey,
    			@value_name='ErrorLogFile',
    			@value=@regvalue OUTPUT,
    			@output = 'no_output'

		SELECT @Path = REPLACE(@regvalue,'\SQLAGENT.OUT','')
	END

	
	--Get Dir From Path
	BEGIN
		IF OBJECT_ID('tempdb..#Files') IS NOT NULL DROP TABLE #Files;
		SELECT * 
		INTO	#Files
		FROM [dbo].[DirectoryList] (@Path,'*.txt');

		DECLARE CRmaintplan CURSOR FOR
		SELECT	MP.name,@Path + '\' + Fi.Name
		FROM	MSDB..sysmaintplan_plans MP
				CROSS APPLY (SELECT TOP 1 F.Name FROM #Files F WHERE F.Name LIKE MP.name + '%' ORDER BY DateCreated DESC )Fi;
	END


	OPEN CRmaintplan
	FETCH NEXT
	FROM CRmaintplan INTO @MP_Name,@maintplan
	WHILE @@FETCH_STATUS = 0
	BEGIN

			EXECUTE [dbo].[FileRead] @maintplan,@output OUTPUT;
			INSERT	#MPLog
			SELECT	@MP_Name,@output

	FETCH NEXT FROM CRmaintplan INTO @MP_Name,@maintplan
	END
	CLOSE CRmaintplan
	DEALLOCATE CRmaintplan

	IF @Silance = 0
	SELECT	*
	FROM	#MPLog
END