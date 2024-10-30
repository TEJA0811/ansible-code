-- Input: database name
CREATE OR REPLACE FUNCTION create_dcs_roles_and_schemas(
	idm_rpt_data_password character varying,
	idmrptuser_password character varying)
RETURNS integer AS
$BODY$
DECLARE
	cmd varchar(512);
    table_info RECORD;
BEGIN

  IF EXISTS (SELECT 1 FROM pg_catalog.pg_user WHERE usename = 'idmrptsrv') THEN
    ALTER USER idmrptsrv RENAME TO idm_rpt_data;
    cmd := 'ALTER ROLE idm_rpt_data WITH LOGIN PASSWORD ''' || idm_rpt_data_password || '''';
    execute cmd;
    RAISE NOTICE 'Renamed user idmrptsrv to idm_rpt_data';
  ELSE
    -- Create user idm_rpt_data if it does not exist
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_user WHERE  usename = 'idm_rpt_data') THEN
      cmd := 'CREATE ROLE idm_rpt_data WITH LOGIN PASSWORD ''' || idm_rpt_data_password || '''';
      execute cmd;
      RAISE NOTICE 'Created user idm_rpt_data';
    END IF;
  END IF;

  -- Create user idmrptuser if it does not exist
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_user WHERE  usename = 'idmrptuser') THEN
    cmd := 'CREATE ROLE idmrptuser WITH LOGIN PASSWORD ''' || idmrptuser_password || '''';
    execute cmd;
    RAISE NOTICE 'Created user idmrptuser';
  END IF;

  -- Create esec_user role if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_authid WHERE rolname = 'esec_user') THEN
    CREATE ROLE esec_user WITH NOLOGIN;
    RAISE NOTICE 'Created role esec_user';
  END IF;

  -- Create esec_app role if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_authid WHERE rolname = 'esec_app') THEN
    CREATE ROLE esec_app WITH NOLOGIN;
    RAISE NOTICE 'Created role esec_app';
  END IF;

  -- Grant esec_user role to idm_rpt_data
  IF NOT EXISTS (
          SELECT 1
          FROM pg_auth_members a,
               pg_roles r,
               pg_roles m
          WHERE a.roleid = r.oid
          AND   a.member = m.oid
          AND   r.rolname = 'esec_user'
          AND   m.rolname = 'idm_rpt_data'
  ) THEN
    EXECUTE 'GRANT esec_user TO idm_rpt_data';
    RAISE NOTICE 'Granted role esec_user to idm_rpt_data';
  END IF;

  -- Create idm_rpt_data schema if it does not exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE catalog_name = current_catalog AND schema_name = 'idm_rpt_data') THEN
    CREATE SCHEMA idm_rpt_data AUTHORIZATION idm_rpt_data;
    RAISE NOTICE 'Created schema idm_rpt_data';
  ELSE
    ALTER SCHEMA idm_rpt_data OWNER to idm_rpt_data;  
    RAISE NOTICE 'Altered owner of schema idm_rpt_data to idm_rpt_data';
  END IF;

  -- Grant create on schema public to idm_rpt_data
  GRANT CREATE ON SCHEMA public TO idm_rpt_data;
  RAISE NOTICE 'Granted CREATE on schema public to user idm_rpt_data';

  -- Grant  usage on schema idm_rpt_data to idmrptuser  
  GRANT USAGE ON SCHEMA idm_rpt_data TO idmrptuser;
  RAISE NOTICE 'Granted USAGE on schema idm_rpt_data to user idmrptuser';
  
  -- If the public.databasechangelog table exists, create one new table from it for idm_rpt_data
  IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'databasechangelog') THEN
    CREATE TABLE idm_rpt_data.databasechangelog (LIKE public.databasechangelog INCLUDING DEFAULTS INCLUDING INDEXES INCLUDING CONSTRAINTS);
    ALTER TABLE idm_rpt_data.databasechangelog OWNER TO idm_rpt_data;    
    INSERT INTO idm_rpt_data.databasechangelog SELECT * from public.databasechangelog WHERE filename = 'IdmRptDataSchemaChangeLog.xml' OR filename = 'IdmRptDataOTBDataChangeLog.xml';
    UPDATE idm_rpt_data.databasechangelog set author = 'idmrpt' where author = 'idmrptsrv';
    RAISE NOTICE 'Created idm_rpt_data.databasechangelog table.';
  END IF;

-- If the public.databasechangeloglock table exists, create one new table from it for idm_rpt_data
  IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'databasechangeloglock') THEN
    CREATE TABLE idm_rpt_data.databasechangeloglock (LIKE public.databasechangeloglock INCLUDING DEFAULTS INCLUDING INDEXES INCLUDING CONSTRAINTS);
    ALTER TABLE idm_rpt_data.databasechangeloglock OWNER TO idm_rpt_data;
    INSERT INTO idm_rpt_data.databasechangeloglock SELECT * from public.databasechangeloglock;
    RAISE NOTICE 'Created idm_rpt_data.databasechangeloglock table.';
  END IF;

  -- Alter the owner of all of the tables in the idm_rpt_data schema to be idm_rpt_data
  FOR table_info IN SELECT * from pg_tables where schemaname = 'idm_rpt_data' and tableowner != 'idm_rpt_data' LOOP
    cmd := 'ALTER TABLE idm_rpt_data.' || table_info.tablename || ' OWNER TO idm_rpt_data';
    EXECUTE cmd;
    RAISE NOTICE 'Altered owner of table idm_rpt_data.% to idm_rpt_data', table_info.tablename;
  END LOOP;

  -- Grant select on events_rpt_v3 to idmrptuser
  IF EXISTS(SELECT 1 FROM information_schema.views WHERE table_schema = 'public' AND table_name = 'events_rpt_v3') THEN
    GRANT SELECT ON public.events_rpt_v3 to idmrptuser;
    RAISE NOTICE 'Granted SELECT on public.events_rpt_v3 to idmrptuser';
  END IF;

  -- Grant select on evt_agent_rpt_v to idmrptuser
  IF EXISTS(SELECT 1 FROM information_schema.views WHERE table_schema = 'public' AND table_name = 'evt_agent_rpt_v') THEN
    GRANT SELECT ON public.evt_agent_rpt_v to idmrptuser;
    RAISE NOTICE 'Granted SELECT on public.evt_agent_rpt_v to idmrptuser';
  END IF;

  -- Grant select on evt_xdas_txnmy_rpt_v to idmrptuser
  IF EXISTS(SELECT 1 FROM information_schema.views WHERE table_schema = 'public' AND table_name = 'evt_xdas_txnmy_rpt_v') THEN
    GRANT SELECT ON public.evt_xdas_txnmy_rpt_v to idmrptuser;
    RAISE NOTICE 'Granted SELECT on public.evt_xdas_txnmy_rpt_v to idmrptuser';
  END IF;

  -- Drop and recreate indexes for performance improvement (requires dba privileges)
  IF EXISTS(SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'events') THEN
    DROP INDEX IF EXISTS events_domain_user_idx;
    CREATE INDEX events_domain_user_idx on public.events (lower(rv45), lower(dun));
    RAISE NOTICE 'Altered index public.events.events_domain_user_idx to use columns lower(rv45), lower(dun)';
  END IF;

  IF EXISTS(SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'hist_events') THEN
    DROP INDEX IF EXISTS hist_events_domain_user_idx;
    CREATE INDEX hist_events_domain_user_idx on public.hist_events (lower(rv45), lower(dun));
    RAISE NOTICE 'Altered index public.hist_events.hist_events_domain_user_idx to use columns lower(rv45), lower(dun)';
  END IF;

  GRANT SELECT ON ALL TABLES IN SCHEMA public TO esec_user WITH GRANT OPTION;
  RAISE NOTICE 'Granted SELECT with GRANT OPTION on all tables in public schema to role esec_user';

  -- Return 0 for success
  RETURN 0;
END;
$BODY$
LANGUAGE plpgsql
/* Put semicolon on its own line so that this will be treated as a single statement by the maven SQL plutin */
;
