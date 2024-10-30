CREATE OR REPLACE PROCEDURE create_dcs_roles_and_schemas(
	idm_rpt_data_password character varying,
	idmrptuser_password character varying)
AUTHID CURRENT_USER
AS
	cnt number;
BEGIN

	/* Create user IDM_RPT_DATA if it does not exist already */
	select count(*) into cnt from ALL_USERS WHERE USERNAME = 'IDM_RPT_DATA'; 
	IF cnt = 0 THEN
		execute immediate 'CREATE USER idm_rpt_data IDENTIFIED BY ' || idm_rpt_data_password;
		DBMS_OUTPUT.put_line('Created user idm_rpt_data');
	END IF;
	
	/* Grant rights to the idm_rpt_data user */
	execute immediate 'GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER, UNLIMITED TABLESPACE to idm_rpt_data';
	DBMS_OUTPUT.put_line('Granted rights to user idm_rpt_data');

	/* Create user IDMRPTUSER if it does not exist */
	select count(*) into cnt from ALL_USERS WHERE USERNAME = 'IDMRPTUSER'; 
	IF cnt = 0 THEN
		execute immediate 'CREATE USER idmrptuser IDENTIFIED BY ' || idmrptuser_password;
		DBMS_OUTPUT.put_line('Created user idmrptuser');
	END IF;
	
	/* Grant rights to the idmrptuser user */
	execute immediate 'GRANT CREATE SESSION to idmrptuser';
	DBMS_OUTPUT.put_line('Granted rights to user idmrptuser');
END;