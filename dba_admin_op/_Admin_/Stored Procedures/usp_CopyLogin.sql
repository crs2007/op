-- =============================================
-- Author:		Sharon
-- Create date: 22/12/2016
-- Description:	CleanUP
-- =============================================
CREATE PROCEDURE [_Admin_].[usp_CopyLogin]
	@LoginName sysname = NULL
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @cmd NVARCHAR(MAX) = N'';

-- Scripting Out the Logins To Be Created
SELECT @cmd+= N'
-- Logins To Be Created --
IF (SUSER_ID('+QUOTENAME(SP.name,'''')+') IS NOT NULL) 
BEGIN 
	DROP LOGIN ' +QUOTENAME(SP.name)+ ';
END
	CREATE LOGIN ' +QUOTENAME(SP.name)+
			   CASE 
					WHEN SP.type_desc = 'SQL_LOGIN' THEN ' WITH 
		PASSWORD = ' +CONVERT(NVARCHAR(MAX),SL.password_hash,1)+ ' HASHED, 
		CHECK_EXPIRATION = ' + CASE WHEN SL.is_expiration_checked = 1 THEN 'ON' ELSE 'OFF' END +', 
		CHECK_POLICY = ' +CASE WHEN SL.is_policy_checked = 1 THEN 'ON,' ELSE 'OFF,' END
					ELSE ' FROM WINDOWS WITH'
				END 
	   +' DEFAULT_DATABASE=[' +SP.default_database_name+ '], 
		DEFAULT_LANGUAGE=[' +SP.default_language_name+ '] '
		+ CASE SP.type WHEN 'S' THEN ',SID = ' + CONVERT(NVARCHAR(MAX),SP.sid,1) COLLATE SQL_Latin1_General_CP1_CI_AS --AS [-- Logins To Be Created --]
		ELSE '' END
FROM	sys.server_principals AS SP 
		LEFT JOIN sys.sql_logins AS SL ON SP.principal_id = SL.principal_id
WHERE	SP.type IN ('S','G','U')
		AND SP.name NOT LIKE '##%##'
		AND SP.name NOT LIKE 'NT AUTHORITY%'
		AND SP.name NOT LIKE 'NT SERVICE%'
		AND SP.name <> ('sa')
		AND EXISTS(SELECT SP.name INTERSECT SELECT @LoginName);
 /*
 IF (SUSER_ID('centerity') IS NULL) BEGIN CREATE LOGIN [centerity] WITH PASSWORD = 0x0200A9E5B3C5F4F92EAC3C975F46A0DB3A55AD37ED1B1353A1DE6B665BBBECF857DDBB4BBCE5643F7C1C3D62FCF104D1CE3D9D178D4B5324F2451F5FBE17F54B2C28078AF8D9 HASHED, CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english] END;
 */
-- Scripting Out the Role Membership to Be Added
SELECT @cmd+= N'
-- Server Roles the Logins Need to be Added --
EXEC master..sp_addsrvrolemember @loginame = N''' + SL.name + ''', @rolename = N''' + SR.name + '''
' --AS [-- Server Roles the Logins Need to be Added --]
FROM master.sys.server_role_members SRM
	INNER JOIN master.sys.server_principals SR ON SR.principal_id = SRM.role_principal_id
	INNER JOIN master.sys.server_principals SL ON SL.principal_id = SRM.member_principal_id
WHERE SL.type IN ('S','G','U')
		AND SL.name NOT LIKE '##%##'
		AND SL.name NOT LIKE 'NT AUTHORITY%'
		AND SL.name NOT LIKE 'NT SERVICE%'
		AND SL.name <> ('sa')
		AND EXISTS(SELECT SL.name INTERSECT SELECT @LoginName);
 
 
-- Scripting out the Permissions to Be Granted
SELECT @cmd+= N'
-- Server Level Permissions to Be Granted --
' +
	CASE WHEN SrvPerm.state_desc <> 'GRANT_WITH_GRANT_OPTION' 
		THEN SrvPerm.state_desc 
		ELSE 'GRANT' 
	END
    + ' ' + SrvPerm.permission_name + ' TO [' + SP.name + ']' + 
	CASE WHEN SrvPerm.state_desc <> 'GRANT_WITH_GRANT_OPTION' 
		THEN '' 
		ELSE ' WITH GRANT OPTION' 
	END collate database_default --AS [-- Server Level Permissions to Be Granted --] 
FROM	sys.server_permissions AS SrvPerm 
		INNER JOIN sys.server_principals AS SP ON SrvPerm.grantee_principal_id = SP.principal_id 
WHERE   SP.type IN ( 'S', 'U', 'G' ) 
		AND SP.name NOT LIKE '##%##'
		AND SP.name NOT LIKE 'NT AUTHORITY%'
		AND SP.name NOT LIKE 'NT SERVICE%'
		AND SP.name <> ('sa')
		AND EXISTS(SELECT SP.name INTERSECT SELECT @LoginName);

		PRINT @cmd;
END