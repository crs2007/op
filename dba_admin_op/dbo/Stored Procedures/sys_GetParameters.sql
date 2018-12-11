CREATE PROCEDURE dbo.sys_GetParameters
    @object_name NVARCHAR(511)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @object_id INT,
        @paramID INT,
        @paramName SYSNAME,
        @definition NVARCHAR(MAX),
        @t NVARCHAR(MAX),
        @loc1 INT,
        @loc2 INT,
        @loc3 INT,
        @loc4 INT,
        @has_default_value BIT;

    SET @object_id = OBJECT_ID(@object_name);

    IF (@object_id IS NOT NULL)
    BEGIN
    
        SELECT @definition = OBJECT_DEFINITION(@object_id);

        CREATE TABLE #params
        (
            parameter_id        INT PRIMARY KEY,
            has_default_value    BIT NOT NULL DEFAULT (0)
        );

        DECLARE c CURSOR
        LOCAL FORWARD_ONLY STATIC READ_ONLY
        FOR 
            SELECT 
                parameter_id,
                [name]
            FROM
                sys.parameters
            WHERE
                [object_id] = @object_id;

        OPEN c;

        FETCH NEXT FROM c INTO @paramID, @paramName;

        WHILE (@@FETCH_STATUS = 0)
        BEGIN
    
            SELECT
                @t = SUBSTRING
                (
                    @definition,
                    CHARINDEX(@paramName, @definition),
                    4000
                ),
                @has_default_value = 0;
            
            SET @loc1 = COALESCE(NULLIF(CHARINDEX('''', @t), 0), 4000);
            SET @loc2 = COALESCE(NULLIF(CHARINDEX(',', @t), 0), 4000);
            SET @loc3 = NULLIF(CHARINDEX('OUTPUT', @t), 0);
            SET @loc4 = NULLIF(CHARINDEX('AS', @t), 0);
            
            SET @loc1 = CASE WHEN @loc2 < @loc1 THEN @loc2 ELSE @loc1 END;
            SET @loc1 = CASE WHEN @loc3 < @loc1 THEN @loc3 ELSE @loc1 END;
            SET @loc1 = CASE WHEN @loc4 < @loc1 THEN @loc4 ELSE @loc1 END;
            
            IF CHARINDEX('=', LTRIM(RTRIM(SUBSTRING(@t, 1, @loc1)))) > 0
                SET @has_default_value = 1;

            INSERT #params
            (
                parameter_id,
                has_default_value
            )
            SELECT
                @paramID,
                @has_default_value;
            
            FETCH NEXT FROM c INTO @paramID, @paramName;
        END
        
        SELECT 
            sp.[object_id],
            [object_name] = @object_name,
            param_name = sp.[name],
            sp.parameter_id,
            type_name = UPPER(st.[name]),
            sp.max_length,
            sp.[precision],
            sp.scale,
            sp.is_output,
            p.has_default_value
        FROM
            sys.parameters sp
			INNER JOIN #params p ON sp.parameter_id = p.parameter_id
			INNER JOIN sys.types st ON sp.user_type_id = st.user_type_id
        WHERE
            sp.[object_id] = @object_id;
        
        CLOSE c;
        DEALLOCATE c;
        DROP TABLE #params;
    END
END