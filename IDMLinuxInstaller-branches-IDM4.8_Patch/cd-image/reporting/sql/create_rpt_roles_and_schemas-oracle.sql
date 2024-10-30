CREATE OR REPLACE PROCEDURE create_rpt_roles_and_schemas(
	idm_rpt_cfg_password character varying)
AUTHID CURRENT_USER
AS
	cnt number;
BEGIN

	/* Create user IDM_RPT_CFG if it does not exist */
	select count(*) into cnt from ALL_USERS WHERE USERNAME = 'IDM_RPT_CFG'; 
	IF cnt = 0 THEN
		execute immediate 'CREATE USER idm_rpt_cfg IDENTIFIED BY ' || idm_rpt_cfg_password;
		DBMS_OUTPUT.put_line('Created user idm_rpt_cfg');
	END IF;
	
	/* Grant rights to the idm_rpt_cfg user */
	execute immediate 'GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER, UNLIMITED TABLESPACE to idm_rpt_cfg';
	DBMS_OUTPUT.put_line('Granted rights to user idm_rpt_cfg');
END;

