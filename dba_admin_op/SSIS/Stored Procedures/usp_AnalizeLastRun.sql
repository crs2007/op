-- =============================================
-- Author:		Sharon
-- Create date: 19/01/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [SSIS].[usp_AnalizeLastRun]
	@RunDate datetime
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @RunNumber uniqueidentifier
	SELECT	TOP 1 @RunNumber = RunNumber
    FROM	SSIS.JobExecuteInfo JEI
	WHERE	JEI.FullDateTime BETWEEN format(@RunDate,'yyyyMMdd 21:30:00.000') AND format(@RunDate,'yyyyMMdd 22:30:00.000');
WITH CTE AS (
	SELECT	JEI.JobName,JEI.StepID,JEI.StepName,
			CONVERT(nvarchar(MAX),REPLACE(JEI.PackageName,'.dtsx','') + '::>' + CONVERT(nvarchar(20),PH.ID)) [Hierarchy],
			1 [Level],
			DATEDIFF(MINUTE,JEI.PackageStartTime,JEI.MessageTime)[AggDuration],PH.executable_name,
			JEI.FullDateTime,JEI.JobDuration,JEI.PackageRunDuration,JEI.ElapsedTime,JEI.MessageTime,JEI.MessageDescription,JEI.MessageSourceDescription,JEI.Message,JEI.MessageExecutionStatus,JEI.MessageGenerated,JEI.PackageName,JEI.PackageStartTime,JEI.PackageEndTime,
			PH.ID,PH.Parent_PackageHierarchy
    FROM	SSIS.JobExecuteInfo JEI
			INNER JOIN SSIS.PackageHierarchy PH ON PH.PackageName = JEI.PackageName COLLATE DATABASE_DEFAULT 
				AND JEI.message LIKE PH.[executable_name] + '%' COLLATE DATABASE_DEFAULT 
	WHERE	PH.Parent_PackageHierarchy IS NULL
			AND JEI.RunNumber = @RunNumber
			--AND PH.ID NOT IN (SELECT [SheardEndConector] FROM SSIS.PackageHierarchy WHERE [SheardEndConector] IS NOT NULL)
	UNION ALL 
	SELECT	JEI.JobName,JEI.StepID,JEI.StepName,
			c.[Hierarchy] + '>' + CONVERT(nvarchar(20),PH.ID) [Hierarchy],
			C.[Level] + 1 [Level],
			DATEDIFF(MINUTE,JEI.PackageStartTime,JEI.MessageTime)[AggDuration],PH.executable_name,
			JEI.FullDateTime,JEI.JobDuration,JEI.PackageRunDuration,JEI.ElapsedTime,JEI.MessageTime,JEI.MessageDescription,JEI.MessageSourceDescription,JEI.Message,JEI.MessageExecutionStatus,JEI.MessageGenerated,JEI.PackageName,JEI.PackageStartTime,JEI.PackageEndTime,
			PH.ID,PH.Parent_PackageHierarchy
    FROM	CTE C 
			INNER JOIN SSIS.JobExecuteInfo JEI ON C.PackageName = JEI.PackageName
				AND JEI.RunNumber = @RunNumber
			INNER JOIN SSIS.PackageHierarchy PH ON PH.PackageName = JEI.PackageName COLLATE DATABASE_DEFAULT 
				AND JEI.message LIKE PH.[executable_name] + '%' COLLATE DATABASE_DEFAULT 
				AND PH.Parent_PackageHierarchy = C.ID
	WHERE	PH.Parent_PackageHierarchy IS NOT NULL
			--
)	SELECT	*,MAX([AggDuration]) OVER(PARTITION BY C.PackageName)
    FROM	CTE c
	ORDER BY C.StepID ASC,IIF(C.message	LIKE '%:Finished,%',999,C.Parent_PackageHierarchy) ASC
	
END