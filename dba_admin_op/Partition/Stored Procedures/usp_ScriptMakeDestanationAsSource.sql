-- =============================================
-- Author:		Sharon
-- Create date: 23/02/2016
-- Update date: 03/03/2016
--				26/07/2016 Sharon CASE WHEN ix.fill_factor = 0 THEN 100 ELSE ix.fill_factor END
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Partition].[usp_ScriptMakeDestanationAsSource]
	@TableName sysname,
	@DestanationTableName sysname,
	@FileGroup sysname = 'Secondary',
	@PartitionNumber INT,
	@Drop NVARCHAR(MAX) OUTPUT,
	@Create NVARCHAR(MAX) OUTPUT,
	@AdditionalText nvarchar(255) = ''
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT @Create = N'',@Drop = N'TRUNCATE TABLE '+ @DestanationTableName + ';
';
	
 SELECT DISTINCT @Create +=  N'
IF NOT EXISTs(SELECT TOP 1 1 FROM sys.indexes i WHERE i.name = ''' + CONCAT(ix.name,IIF(@DestanationTableName IS NULL,N'',N'_Temp'+ISNULL(@AdditionalText,''))) COLLATE DATABASE_DEFAULT +''')
' + IIF(ix.is_primary_key=0,'CREATE ' + case when ix.is_unique = 1 then 'UNIQUE ' else '' END + ix.type_desc + ' INDEX ' + QUOTENAME(CONCAT(ix.name,IIF(@DestanationTableName IS NULL,N'',N'_Temp'+ISNULL(@AdditionalText,'')))) COLLATE DATABASE_DEFAULT +' ON ' + ISNULL(DT.[DestanationTable],QUOTENAME(schema_name(t.schema_id)) COLLATE DATABASE_DEFAULT +'.'+ QUOTENAME(t.name) COLLATE DATABASE_DEFAULT) ,
		 N'ALTER TABLE ' + QUOTENAME(schema_name(t.schema_id)) COLLATE DATABASE_DEFAULT +'.'+ QUOTENAME(t.name) COLLATE DATABASE_DEFAULT+ ' ADD CONSTRAINT ' + QUOTENAME(ix.name) COLLATE DATABASE_DEFAULT +' PRIMARY KEY '+ ix.type_desc + N' ') + 
		 '(' + SUBSTRING(IC.IColumn,0,LEN(IC.IColumn)) COLLATE DATABASE_DEFAULT+') '
		  + IIF(INC.IColumn IS NOT NULL,'INCLUDE (' + SUBSTRING(INC.IColumn,0,LEN(INC.IColumn)) COLLATE DATABASE_DEFAULT+ ')',N'') + ' 
WITH (' 
		  + case when ix.is_padded=1 then 'PAD_INDEX = ON, ' else 'PAD_INDEX = OFF, ' end
		 + case when ix.allow_page_locks=1 then 'ALLOW_PAGE_LOCKS = ON, ' else 'ALLOW_PAGE_LOCKS = OFF, ' end
		 + case when ix.allow_row_locks=1 then  'ALLOW_ROW_LOCKS = ON, ' else 'ALLOW_ROW_LOCKS = OFF, ' end
		 + case when INDEXPROPERTY(t.object_id, ix.name COLLATE DATABASE_DEFAULT, 'IsStatistics') = 1 then 'STATISTICS_NORECOMPUTE = ON, ' else 'STATISTICS_NORECOMPUTE = OFF, ' end
		 + case when ix.ignore_dup_key=1 then 'IGNORE_DUP_KEY = ON, ' else 'IGNORE_DUP_KEY = OFF, ' end
		 + 'SORT_IN_TEMPDB = ON ' 
		 + IIF( ix.fill_factor  > 0 , ' ,FILLFACTOR = ' + CONVERT(VARCHAR(10),ix.fill_factor) , ''  )
		 + COMP.[COMPRESSION]
		 + ') ON ' + ISNULL(QUOTENAME(@FileGroup),ISNULL(fg.[FileGroup],QUOTENAME(ds.name)))
 from	sys.tables t 
		inner join sys.indexes ix on t.object_id=ix.object_id
		INNER JOIN sys.data_spaces ds ON ds.data_space_id = ix.data_space_id
		OUTER APPLY(SELECT TOP 1 CASE WHEN p.data_compression > 0 THEN ' ,DATA_COMPRESSION = ' + p.data_compression_desc COLLATE DATABASE_DEFAULT ELSE '' END [COMPRESSION] FROM sys.partitions p WHERE p.object_id = t.object_id AND ix.index_id = p.index_id)COMP
		OUTER APPLY(SELECT QUOTENAME(C.name) +' ' + IIF(ic.is_descending_key = 1,N'DESC',N'ASC') + ',' FROM sys.index_columns ic INNER JOIN sys.columns C ON C.object_id = ic.object_id AND C.column_id = ic.column_id WHERE ic.object_id = t.object_id AND ic.is_included_column = 0 AND ic.index_id = ix.index_id AND (ic.key_ordinal = 1 OR (ic.key_ordinal = 0 AND ic.partition_ordinal > 0))FOR XML PATH(''))IC(IColumn)
		OUTER APPLY(SELECT QUOTENAME(C.name) + ',' FROM sys.index_columns ic	INNER JOIN sys.columns C ON C.object_id = ic.object_id AND C.column_id = ic.column_id WHERE ic.object_id = t.object_id AND ic.is_included_column = 1 AND ic.index_id = ix.index_id FOR XML PATH(''))INC(IColumn)
		OUTER APPLY(SELECT QUOTENAME(s.name) COLLATE DATABASE_DEFAULT +'.'+ QUOTENAME(ST.name) COLLATE DATABASE_DEFAULT [DestanationTable] FROM sys.tables ST INNER JOIN sys.schemas s ON s.schema_id = ST.schema_id WHERE ST.object_id = OBJECT_ID(@DestanationTableName))DT
		OUTER APPLY(SELECT TOP 1 ds.name + '(' + QUOTENAME(c.name) + ')' [FileGroup] FROM sys.index_columns  ic inner join  sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
	where	ix.object_id = ic.object_id
			and ic.index_id = ix.index_id
			and ic.partition_ordinal > 0)fg
  where	ix.type>0 
		AND t.is_ms_shipped=0 
		AND t.name<>'sysdiagrams'
		AND t.object_id = OBJECT_ID(@TableName);
	SELECT @Drop += IIF(ix.is_primary_key=0,N'DROP INDEX ' + QUOTENAME(ix.name) COLLATE DATABASE_DEFAULT +' ON ' + ISNULL(DT.[DestanationTable],QUOTENAME(schema_name(t.schema_id)) COLLATE DATABASE_DEFAULT +'.'+ QUOTENAME(t.name) COLLATE DATABASE_DEFAULT)+ ';
',N'
ALTER TABLE ' + QUOTENAME(schema_name(t.schema_id)) COLLATE DATABASE_DEFAULT +'.'+ QUOTENAME(t.name) COLLATE DATABASE_DEFAULT+ ' DROP CONSTRAINT ' + QUOTENAME(ix.name) COLLATE DATABASE_DEFAULT +';
')
 from	sys.tables t 
		inner join sys.indexes ix on t.object_id=ix.object_id
		INNER JOIN sys.data_spaces ds ON ds.data_space_id = ix.data_space_id
		
		OUTER APPLY(SELECT QUOTENAME(C.name) +' ' + IIF(ic.is_descending_key = 1,N'DESC',N'ASC') + ',' FROM sys.index_columns ic INNER JOIN sys.columns C ON C.object_id = ic.object_id AND C.column_id = ic.column_id WHERE ic.object_id = t.object_id AND ic.is_included_column = 0 AND ic.index_id = ix.index_id FOR XML PATH(''))IC(IColumn)
		OUTER APPLY(SELECT QUOTENAME(C.name) + ',' FROM sys.index_columns ic	INNER JOIN sys.columns C ON C.object_id = ic.object_id AND C.column_id = ic.column_id WHERE ic.object_id = t.object_id AND ic.is_included_column = 1 AND ic.index_id = ix.index_id FOR XML PATH(''))INC(IColumn)
		OUTER APPLY(SELECT QUOTENAME(s.name) COLLATE DATABASE_DEFAULT +'.'+ QUOTENAME(ST.name) COLLATE DATABASE_DEFAULT [DestanationTable] FROM sys.tables ST INNER JOIN sys.schemas s ON s.schema_id = ST.schema_id WHERE ST.object_id = OBJECT_ID(@DestanationTableName))DT
		OUTER APPLY(SELECT TOP 1 ds.name + '(' + QUOTENAME(c.name) + ')' [FileGroup] FROM sys.index_columns  ic inner join  sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
	where	ix.object_id = ic.object_id
			and ic.index_id = ix.index_id
			and ic.partition_ordinal > 0)fg
  where	ix.type>0 
		AND t.is_ms_shipped=0 
		AND t.name<>'sysdiagrams'
		AND t.object_id = OBJECT_ID(@DestanationTableName);

	SELECT	@Create += IIF(cc.name LIKE '%Temp%',N'',N'
ALTER TABLE [' + s.name + '].[' + t.name + ']  WITH CHECK ADD CONSTRAINT [' + cc.name + '] CHECK ' + cc.definition + ';
')
    FROM	sys.check_constraints cc
			INNER JOIN sys.tables t ON t.object_id = cc.parent_object_id
			INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
	where	cc.parent_object_id = OBJECT_ID(@TableName);
	SELECT	@Drop += 'ALTER TABLE [' + s.name + '].[' + t.name + '] DROP CONSTRAINT [' + cc.name + '];
'
    FROM	sys.check_constraints cc
			INNER JOIN sys.tables t ON t.object_id = cc.parent_object_id
			INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
	where	cc.parent_object_id = OBJECT_ID(@DestanationTableName);
END