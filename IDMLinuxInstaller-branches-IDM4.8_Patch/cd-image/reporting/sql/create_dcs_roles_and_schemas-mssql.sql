CREATE PROCEDURE create_dcs_roles_and_schemas(
	@idm_rpt_data_password nvarchar(2000),
	@idmrptuser_password nvarchar(2000))

AS
BEGIN
    DECLARE
	    @cmd nvarchar(MAX);

    -- Create user idm_rpt_data if it does not exist
    IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE name = 'idm_rpt_data')
    BEGIN
      SET @cmd = '
      USE master; 
      IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE name = ''idm_rpt_data'')
        CREATE LOGIN [idm_rpt_data] WITH PASSWORD=N''' + @idm_rpt_data_password + '''
      ';
      EXEC sp_executesql @cmd;
      PRINT 'Created login idm_rpt_data';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.sysusers WHERE name = 'idm_rpt_data')
    BEGIN
      SET @cmd = 'CREATE USER idm_rpt_data FOR LOGIN idm_rpt_data';
      EXEC sp_executesql @cmd;
      PRINT 'Created user idm_rpt_data';
    END

  -- Create user idmrptuser if it does not exist
    IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE name = 'idmrptuser')
    BEGIN
      SET @cmd = '
      USE master; 
      IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE name = ''idmrptuser'')
        CREATE LOGIN [idmrptuser] WITH PASSWORD=N''' + @idmrptuser_password + '''
      ';
      EXEC sp_executesql @cmd;
      PRINT 'Created login idmrptuser';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.sysusers WHERE name = 'idmrptuser')
    BEGIN
      SET @cmd = 'CREATE USER idmrptuser FOR LOGIN idmrptuser';
      EXEC sp_executesql @cmd;
      PRINT 'Created user idmrptuser';
    END

  -- Create idm_rpt_data schema if it does not exist
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'IDM_RPT_DATA') 
	BEGIN
		SET @cmd = 'CREATE SCHEMA IDM_RPT_DATA AUTHORIZATION idm_rpt_data';
		EXEC sp_executesql @cmd;
		PRINT 'Created schema IDM_RPT_DATA';
	END
	ELSE
	BEGIN
		SET @cmd = 'ALTER AUTHORIZATION ON SCHEMA::IDM_RPT_DATA TO idm_rpt_data';  
		EXEC sp_executesql @cmd;
		PRINT 'Altered owner of schema IDM_RPT_DATA to idm_rpt_data';
	END 

  -- Create idm_rpt_data schema if it does not exist
  IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'idmrptuser') 
	BEGIN
		SET @cmd = 'CREATE SCHEMA idmrptuser AUTHORIZATION idmrptuser';
		EXEC sp_executesql @cmd;
		PRINT 'Created schema idmrptuser';
	END
	ELSE
	BEGIN
		SET @cmd = 'ALTER AUTHORIZATION ON SCHEMA::idmrptuser TO idmrptuser';  
		EXEC sp_executesql @cmd;
		PRINT 'Altered owner of schema idmrptuser to idmrptuser';
	END

  --Grant permissions to IDM_RPT_DATA
  GRANT ALL TO idm_rpt_data;

  --Grant permissions to idmrptuser (to be added as required)
  --GRANT CREATE TO idmrptuser;

  -- create_rpt_roles_and_schemas part (creates idm_rpt_cfg). 
  --We are adding it here because mssql does not allow two batch of stored procedures(delete and create). Can be separated and called by installer later.

  IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE name = 'idm_rpt_cfg')
	BEGIN
		SET @cmd = '
		USE master; 
		IF NOT EXISTS (SELECT 1 FROM sys.syslogins WHERE name = ''idm_rpt_cfg'')
			CREATE LOGIN [idm_rpt_cfg] WITH PASSWORD=N''' + @idm_rpt_data_password + '''
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

  --- Grant permission to idm_rpt_cfg
  GRANT ALL TO idm_rpt_cfg;
  -- Return 0 for success
  RETURN 0;
END
;

/* Put semicolon on its own line so that this will be treated as a single statement by the maven SQL plutin */

