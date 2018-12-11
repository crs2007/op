CREATE PROC ListObjectDependentSSISPackages
    @FolderPath VARCHAR(1000) ,
    @ObjectName VARCHAR(100) ,
    @ObjectType VARCHAR(10)
AS
    IF OBJECT_ID('DTSPackages') IS NOT NULL
        DROP TABLE DTSPackages;
 
    CREATE TABLE DTSPackages ( x XML );
    IF OBJECT_ID('tempdb..#DirectoryTree') IS NOT NULL
        DROP TABLE #DirectoryTree;
 
    CREATE TABLE #DirectoryTree
        (
          id INT IDENTITY(1, 1) ,
          subdirectory NVARCHAR(512) ,
          depth INT ,
          isfile BIT
        );
 
    INSERT  #DirectoryTree
            ( subdirectory ,
              depth ,
              isfile
            )
            EXEC master.sys.xp_dirtree @FolderPath, 1, 1;
 
    DECLARE @Path VARCHAR(100) ,
        @ID INT;
 
 
 
    SELECT TOP 1
            @Path = subdirectory ,
            @ID = id
    FROM    #DirectoryTree
    WHERE   isfile = 1
            AND subdirectory LIKE '%.dtsx'
    ORDER BY id;
 
 
 
 
 
    WHILE @Path IS NOT NULL
        BEGIN
            DECLARE @SQL VARCHAR(MAX) = 'INSERT DTSPackages
SELECT *
FROM OPENROWSET(BULK ''' + @FolderPath + '\' + @Path + ''',
   SINGLE_BLOB) AS x;';
    
            EXEC (@SQL);
            SET @Path = NULL;
            SELECT TOP 1
                    @Path = subdirectory ,
                    @ID = id
            FROM    #DirectoryTree
            WHERE   isfile = 1
                    AND subdirectory LIKE '%.dtsx'
                    AND id > @ID
            ORDER BY id;
        END;
      
    IF @ObjectType = 'Column'
        BEGIN
            WITH XMLNAMESPACES ('www.microsoft.com/SqlServer/Dts' AS DTS)
   SELECT   t.u.value('.','varchar(100)')
   FROM DTSPackages
   CROSS APPLY x.nodes('/DTS:Executable/DTS:Property[@DTS:Name="ObjectName"]')t(u)
   WHERE x.exist('//inputColumn[@name=sql:variable("@ObjectName")]') = 1
   OR x.exist('//externalMetadataColumn[@name=sql:variable("@ObjectName")]') = 1
   OR x.exist('//outputColumn[@name=sql:variable("@ObjectName")]') = 1
   OR x.exist('//DTS:Variable/DTS:VariableValue[contains(.,sql:variable("@ObjectName"))]')=1;
        END;
    
    IF @ObjectType = 'Table'
        BEGIN
            WITH XMLNAMESPACES ('www.microsoft.com/SqlServer/Dts' AS DTS,'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask)
   SELECT   t.u.value('.','varchar(100)')
   FROM DTSPackages
   CROSS APPLY x.nodes('/DTS:Executable/DTS:Property[@DTS:Name="ObjectName"]')t(u)
   WHERE
   x.exist('//SQLTask:SqlTaskData[contains(./@SQLTask:SqlStatementSource,sql:variable("@ObjectName"))]')=1
   OR x.exist('//property[@name="SqlCommand" and contains(.,sql:variable("@ObjectName"))]')=1
   OR x.exist('//DTS:Variable[@DTS:Name="Expression" and contains(.,sql:variable("@ObjectName"))]')=1
   OR x.exist('//DTS:Variable/DTS:VariableValue[contains(.,sql:variable("@ObjectName"))]')=1;
    
        END;