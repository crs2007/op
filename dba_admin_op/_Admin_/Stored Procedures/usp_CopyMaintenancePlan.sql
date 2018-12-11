-- =============================================
-- Author:		Sharon
-- Create date: 22/12/2016
-- Description:	MaintenancePlan
-- =============================================
CREATE PROCEDURE [_Admin_].[usp_CopyMaintenancePlan]
	@MaintenancePlanName sysname = NULL
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @cmd NVARCHAR(MAX) = N'';

-- Scripting Out the Logins To Be Created
SELECT  @cmd = @cmd + 
N'
INSERT msdb.dbo.sysssispackages VALUES(' + 
ISNULL(N'''' + name + N'''',N'NULL') + N',
' + ISNULL(N'N''' + CONVERT(NVARCHAR(36),id) + N'''', N'NULL') + N',
' + ISNULL(N'N''' + description + N'''', N'N''Copied Maintenance Plan''') + N',
' + ISNULL(N'N''' + CONVERT(NVARCHAR(25),createdate,121) + N'''', N'NULL') + N',
' + ISNULL(N'N''' + CONVERT(NVARCHAR(36),folderid) + N'''', N'NULL') + N',
' + ISNULL(CONVERT(NVARCHAR(MAX),ownersid,1), N'NULL') + N',
' + vp.Pkg + N',
' + ISNULL(CONVERT(NVARCHAR(50),packageformat), N'NULL') + N',
' + ISNULL(CONVERT(NVARCHAR(50),packagetype), N'NULL') + N',
' + ISNULL(CONVERT(NVARCHAR(50),vermajor), N'NULL') + N',
' + ISNULL(CONVERT(NVARCHAR(50),verminor), N'NULL') + N',
' + ISNULL(CONVERT(NVARCHAR(50),verbuild), N'NULL') + N',
' + ISNULL(N'N''' + vercomments + N'''', N'NULL') + N',
' + ISNULL(N'N''' + CONVERT(NVARCHAR(36),verid) + N'''', N'NULL') + N',
' + ISNULL(CONVERT(NVARCHAR(2),isencrypted), N'NULL') + N',
' + ISNULL(CONVERT(NVARCHAR(MAX),readrolesid,1), N'NULL') + N',
' + ISNULL(CONVERT(NVARCHAR(MAX),writerolesid,1),N'NULL') + N');
GO

'    
FROM
    msdb.dbo.sysssispackages AS P
	CROSS APPLY (SELECT TOP 1 ISNULL(CONVERT(NVARCHAR(MAX),cast(
    cast(
        replace(
            cast(
                CAST(P.packagedata AS VARBINARY(MAX)) AS varchar(max)
            ), 
       @@SERVERNAME, N'ANAF\ANAF') 
    as XML) 
as VARBINARY(MAX)),1) ,N'NULL') Pkg)VP
WHERE        
    (P.name LIKE 'mp%' AND P.description IS NULL)
	AND (@MaintenancePlanName IS NULL OR P.name = @MaintenancePlanName);
	
	EXECUTE [_Admin].[dbo].[PrintMax] @cmd;
	SELECT @cmd
END