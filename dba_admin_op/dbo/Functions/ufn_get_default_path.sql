CREATE FUNCTION dbo.[ufn_get_default_path](@log bit, @value_name nvarchar(20)) 
  RETURNS nvarchar(260) 
AS 
  BEGIN 
    DECLARE @instance_name nvarchar(200)
          , @system_instance_name nvarchar(200)
          , @registry_key nvarchar(512)
          , @path nvarchar(260); 
    SET @instance_name = COALESCE(convert(nvarchar(20), serverproperty('InstanceName')), 'MSSQLSERVER'); -- sql 2005/2008 with instance 
    EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL', @instance_name, @system_instance_name output; 
    
    SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer'; 
	IF @value_name = N'DefaultData' 
	BEGIN
		IF @log = 1 
		  BEGIN 
			SET @value_name = N'DefaultLog'; 
		  END 
    
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @registry_key, @value_name, @path output; 
    
		IF @log = 0 AND @path is null -- sql 2005/2008 default instance 
		  BEGIN 
			SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\Setup'; 
			EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @registry_key, N'SQLDataRoot', @path output; 
			SET @path = @path + '\Data'; 
		  END 
    
		IF @path IS NULL -- sql 2000 with instance 
		  BEGIN 
			SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @instance_name + '\MSSQLServer'; 
			EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @registry_key, @value_name, @path output; 
		  END 
      
		IF @path IS NULL -- sql 2000 default instance 
		  BEGIN 
			SET @registry_key = N'Software\Microsoft\MSSQLServer\MSSQLServer'; 
			EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @registry_key, @value_name, @path output; 
		  END 
      
		IF @log = 1 AND @path is null -- sql 2005/2008 default instance 
		  BEGIN 
			SELECT @path = dbo.ufn_get_default_path(0,@value_name) 
		  END 
    
	END
	ELSE
	BEGIN
		SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @instance_name + '\MSSQLServer'; 
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', @registry_key, @value_name, @path output; 		
	END
    RETURN @path; 
  END