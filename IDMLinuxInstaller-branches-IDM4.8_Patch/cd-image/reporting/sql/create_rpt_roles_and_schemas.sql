-- Input: database name
CREATE OR REPLACE FUNCTION create_rpt_roles_and_schemas(
	idm_rpt_cfg_password character varying)
RETURNS integer AS
$BODY$
DECLARE
	cmd varchar(512);
    table_info RECORD;
BEGIN

  -- Create user idm_rpt_cfg if it does not exist
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_user WHERE  usename = 'idm_rpt_cfg') THEN
    cmd := 'CREATE ROLE idm_rpt_cfg WITH LOGIN PASSWORD ''' || idm_rpt_cfg_password || '''';
    execute cmd;
    RAISE NOTICE 'Created user idm_rpt_cfg';
  END IF;

  -- Create idm_rpt_cfg schema schema if it does not exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE catalog_name = current_catalog AND schema_name = 'idm_rpt_cfg') THEN
    CREATE SCHEMA idm_rpt_cfg AUTHORIZATION idm_rpt_cfg;
    RAISE NOTICE 'Created schema idm_rpt_cfg';
  ELSE
    ALTER SCHEMA idm_rpt_cfg OWNER to idm_rpt_cfg;  
    RAISE NOTICE 'Altered owner of schema idm_rpt_cfg to idm_rpt_cfg';
  END IF;
  
  -- Grant create on schema public to idm_rpt_cfg
  GRANT CREATE ON SCHEMA public TO idm_rpt_cfg;
  RAISE NOTICE 'Granted CREATE on schema public to user idm_rpt_cfg';

  -- If the public.databasechangelog table exists, create one new table from it for idm_rpt_cfg
  IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'databasechangelog') THEN
    CREATE TABLE idm_rpt_cfg.databasechangelog (LIKE public.databasechangelog INCLUDING DEFAULTS INCLUDING INDEXES INCLUDING CONSTRAINTS);
    ALTER TABLE idm_rpt_cfg.databasechangelog OWNER TO idm_rpt_cfg;    
    INSERT INTO idm_rpt_cfg.databasechangelog SELECT * from public.databasechangelog WHERE filename != 'IdmRptDataSchemaChangeLog.xml' AND filename != 'IdmRptDataOTBDataChangeLog.xml';
    UPDATE idm_rpt_cfg.databasechangelog set author = 'idmrpt' where author = 'idmrptsrv';
    RAISE NOTICE 'Created idm_rpt_cfg.databasechangelog table.';
  END IF;

-- If the public.databasechangeloglock table exists, create one new tables from it for idm_rpt_cfg
  IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'databasechangeloglock') THEN
    CREATE TABLE idm_rpt_cfg.databasechangeloglock (LIKE public.databasechangeloglock INCLUDING DEFAULTS INCLUDING INDEXES INCLUDING CONSTRAINTS);
    ALTER TABLE idm_rpt_cfg.databasechangeloglock OWNER TO idm_rpt_cfg;
    INSERT INTO idm_rpt_cfg.databasechangeloglock SELECT * from public.databasechangeloglock;
    RAISE NOTICE 'Created idm_rpt_cfg.databasechangeloglock table.';
  END IF;

  -- Alter the owner of all of the tables in the idm_rpt_cfg schema to be idm_rpt_cfg
  FOR table_info IN SELECT * from pg_tables where schemaname = 'idm_rpt_cfg' and tableowner != 'idm_rpt_cfg' LOOP
    cmd := 'ALTER TABLE idm_rpt_cfg.' || table_info.tablename || ' OWNER TO idm_rpt_cfg';
    EXECUTE cmd;
    RAISE NOTICE 'Altered owner of table idm_rpt_cfg.% to idm_rpt_cfg', table_info.tablename;
  END LOOP;

  -- Return 0 for success
  RETURN 0;
END;
$BODY$
LANGUAGE plpgsql
/* Put semicolon on its own line so that this will be treated as a single statement by the maven SQL plutin */
;
