

EXEC master.dbo.sp_addlinkedserver
    @server = N'POSTGRES',
    @srvproduct = N'PostgreSQL',
    @provider = N'MSDASQL',
    @datasrc = N'PostgresDSN';

EXEC master.dbo.sp_addlinkedsrvlogin
    @rmtsrvname = N'POSTGRES',
    @useself = 'FALSE',
    @rmtuser = N'postgres',
    @rmtpassword = N'ailenbuade77';

    EXEC sp_tables_ex 'POSTGRES';