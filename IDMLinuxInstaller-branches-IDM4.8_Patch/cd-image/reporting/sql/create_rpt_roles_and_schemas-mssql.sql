-- Input: database name
IF OBJECT_ID('create_rpt_roles_and_schemas','P') IS NOT NULL
    DROP PROCEDURE create_rpt_roles_and_schemas;
GO

CREATE PROCEDURE create_rpt_roles_and_schemas
	@idm_rpt_cfg_password nvarchar(2000)
AS
BEGIN
    DECLARE
	    @cmd nvarchar(MAX);

    -- Create user idm_rpt_cfg if it does not exist
    IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE name = 'idm_rpt_cfg')
	BEGIN
		SET @cmd = '
		USE master; 
		IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE name = ''idm_rpt_cfg'')
			CREATE LOGIN [idm_rpt_cfg] WITH PASSWORD=N''' + @idm_rpt_cfg_password + '''
		';
		EXEC sp_executesql @cmd;
		PRINT 'Created login idm_rpt_cfg';
	END

    IF NOT EXISTS (SELECT 1 FROM sys.sysusers WHERE name = 'idm_rpt_cfg')
	BEGIN
		SET @cmd = 'CREATE USER idm_rpt_cfg FOR LOGIN idm_rpt_cfg';
		EXEC sp_executesql @cmd;
		PRINT 'Created user idm_rpt_cfg';
	END

	-- Create idm_rpt_cfg schema schema if it does not exist
	IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'IDM_RPT_CFG') 
	BEGIN
		SET @cmd = 'CREATE SCHEMA IDM_RPT_CFG AUTHORIZATION idm_rpt_cfg';
		EXEC sp_executesql @cmd;
		PRINT 'Created schema IDM_RPT_CFG';
	END
	ELSE
	BEGIN
		SET @cmd = 'ALTER AUTHORIZATION ON SCHEMA::IDM_RPT_CFG TO idm_rpt_cfg';  
		EXEC sp_executesql @cmd;
		PRINT 'Altered owner of schema IDM_RPT_CFG to idm_rpt_cfg';
	END 
  
	-- Return 0 for success
	RETURN 0
END
-- Put semicolon on its own line so that this will be treated as a single statement by the maven SQL plugin
;

--exec create_rpt_roles_and_schemas 'compaq1-2'
