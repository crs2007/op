CREATE TABLE [SSIS].[PackageHierarchy] (
    [ID]                      INT            IDENTITY (1, 1) NOT NULL,
    [PackageName]             NVARCHAR (250) NOT NULL,
    [executable_name]         NVARCHAR (250) NOT NULL,
    [Parent_PackageHierarchy] INT            NULL,
    [SheardEndConector]       INT            NULL,
    CONSTRAINT [PK_PackageHierarchy] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_PackageHierarchy_PackageHierarchy_Parent] FOREIGN KEY ([Parent_PackageHierarchy]) REFERENCES [SSIS].[PackageHierarchy] ([ID])
);



