
-- Access-Requests-by-Recipient_4.8.6.0-pg-idmrpt_events_v2.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_events_v2 AS 
 SELECT sentinel_events.id AS event_id,
    sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.fn AS filename,
    sentinel_events.rv35 AS init_user_domain,
    sentinel_events.rv45 AS target_user_domain,
    sentinel_events.rv36,
    sentinel_events.rv40,
    sentinel_events.rv43 AS correlation_id,
    sentinel_events.rv47,
    sentinel_events.rv123 AS event_group_id,
    sentinel_events.rv33,
    sentinel_events.rv31,
    sentinel_events.ei AS extended_info,
    sentinel_events.sres AS sub_resource,
    sentinel_events.sev AS severity,
    sentinel_events.res AS resource_name,
    sentinel_events.sip AS init_ip,
    sentinel_events.isvcc AS init_service_comp,
    sentinel_events.iuid AS init_user_id,
    sentinel_events.destassetid AS target_asset_id,
    sentinel_events.dhn AS target_host_name,
    sentinel_events.dip AS target_ip,
    sentinel_events.dip AS target_ip_dotted,
    sentinel_events.ttd AS target_trust_domain,
    sentinel_events.ttn AS target_trust_name,
    sentinel_events.tuid AS target_user_id,
    sentinel_events.xdasid AS taxonomy_id,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name,
    sentinel_events.xdasid AS xdas_taxonomy_id,
    sentinel_events.attr,
	CASE
    WHEN POSITION('Request Description:' in msg)>0
    THEN  split_part(split_part(sentinel_events.msg::text, ';'::text, 1), ':'::text, 2) END AS request_comment
	
	
   FROM sentinel_events;

ALTER TABLE idm_rpt_data.idmrpt_events_v2
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_events_v2 TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_events_v2 TO idmrptuser;



-- Access-Requests-by-Recipient_4.8.6.0-pg-idmrpt_trustview_v.sql


CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_trustView_all_V AS 
(SELECT 
	 acct.identity_id IDENTITY_ID,
	  role.role_id TRUST_OBJ_ID
      ,assignRoles.TRUST_TYPE_ID
      ,assignRoles.TRUST_STATUS
	   ,(select identity_id from IDM_RPT_DATA.IDMRPT_IDV_ACCT_V where idv_acct_dn= REQUESTOR )  REQUESTOR_ID,
	   removeRoles.requestDate REQUEST_DATE,
	   COMMENT REQUEST_COMMENT,
     assignRoles.CAUSE 
      ,assignRoles.CAUSE_TYPE
      ,assignRoles.APPROVAL_INFO
      ,assignRoles.TRUST_PARAMS
      ,assignRoles.IDV_ENT_ID
      ,assignRoles.IDV_ENT_REF
      ,assignRoles.MS_ENT_ID
      ,assignRoles.IDMRPT_VALID_FROM
      ,assignRoles.IDMRPT_DELETED
      ,assignRoles.TRUST_START_TIME
      ,assignRoles.TRUST_EXPIRATION_TIME
      ,assignRoles.IDMRPT_SYN_STATE 
	  
  FROM 
		(SELECT 
			  msg ,  
			   dun ,
		   ttn ,
		   Case
		   when POSITION('Request Description:' in msg)>0
		   THEN   
		   split_part(split_part(msg::text, ';'::text, 1), ':'::text, 2) END as comment,
		   
		 Case
		   when POSITION('Original Requester:' in msg)>0
		   THEN    
		  split_part(split_part(msg::text, ';'::text, 2), ':'::text, 2) 
		   END as requestor,
		   

		   Case
		   when POSITION('Request Date:' in msg)>0
		   THEN
		  timezone('utc'::text, idm_rpt_data.convertldapTimeToDateTime((split_part(split_part(msg::text, ';'::text,3), ':'::text, 2))) ::timestamp)  END as requestDate
		   
		   

		 ,rv40 ,
		  evt ,
		 sn,
		 obsdom,obsip

			
		FROM sentinel_events events  WHERE (rv40='00031600') AND (evt LIKE '% User Remove :%') )  removeRoles
  LEFT JOIN
  IDM_RPT_DATA.IDMRPT_IDV_V idv on (idv.idv_host = concat(removeRoles.sn,'.',removeRoles.obsdom))
  LEFT JOIN
  IDM_RPT_DATA.IDMRPT_ROLE_V role on (role.role_name = removeRoles.ttn  AND idv.idv_id = role.idv_id)
  LEFT JOIN
  IDM_RPT_DATA.IDMRPT_IDV_ACCT_V acct on acct.idv_acct_cn = removeRoles.dun  

  RIGHT JOIN

  (select * from idmrptdb.IDM_RPT_DATA.IDMRPT_IDV_IDENTITY_TRUST where IDMRPT_DELETED IS true AND TRUST_TYPE_ID='ROLE_ASSIGNMENT')  as assignRoles on  (assignRoles.IDENTITY_ID = acct.identity_id AND assignRoles.TRUST_OBJ_ID = role.role_id)
  where (role_id IS NOT NULL AND idv_acct_id IS NOT NULL))
  
  UNION ALL


  (select IDENTITY_ID
      ,TRUST_OBJ_ID
      ,TRUST_TYPE_ID
      ,TRUST_STATUS
      ,REQUESTER_ID
      ,REQUEST_DATE
      ,REQUEST_COMMENT
      ,CAUSE
      ,CAUSE_TYPE
      ,APPROVAL_INFO
      ,TRUST_PARAMS
      ,IDV_ENT_ID
      ,IDV_ENT_REF
      ,MS_ENT_ID
      ,IDMRPT_VALID_FROM
      ,IDMRPT_DELETED
      ,TRUST_START_TIME
      ,TRUST_EXPIRATION_TIME
      ,IDMRPT_SYN_STATE
  FROM  idmrptdb.IDM_RPT_DATA.IDMRPT_IDV_IDENTITY_TRUST where NOT(TRUST_TYPE_ID='ROLE_ASSIGNMENT' AND IDMRPT_DELETED IS TRUE))
;

ALTER TABLE idm_rpt_data.idmrpt_trustview_all_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_trustview_all_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_trustview_all_v TO idmrptuser;

   
  




-- Access-Requests-by-Requester_4.8.6.0-pg-idmrpt_events_v2.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_events_v2 AS 
 SELECT sentinel_events.id AS event_id,
    sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.fn AS filename,
    sentinel_events.rv35 AS init_user_domain,
    sentinel_events.rv45 AS target_user_domain,
    sentinel_events.rv36,
    sentinel_events.rv40,
    sentinel_events.rv43 AS correlation_id,
    sentinel_events.rv47,
    sentinel_events.rv123 AS event_group_id,
    sentinel_events.rv33,
    sentinel_events.rv31,
    sentinel_events.ei AS extended_info,
    sentinel_events.sres AS sub_resource,
    sentinel_events.sev AS severity,
    sentinel_events.res AS resource_name,
    sentinel_events.sip AS init_ip,
    sentinel_events.isvcc AS init_service_comp,
    sentinel_events.iuid AS init_user_id,
    sentinel_events.destassetid AS target_asset_id,
    sentinel_events.dhn AS target_host_name,
    sentinel_events.dip AS target_ip,
    sentinel_events.dip AS target_ip_dotted,
    sentinel_events.ttd AS target_trust_domain,
    sentinel_events.ttn AS target_trust_name,
    sentinel_events.tuid AS target_user_id,
    sentinel_events.xdasid AS taxonomy_id,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name,
    sentinel_events.xdasid AS xdas_taxonomy_id,
    sentinel_events.attr,
	CASE
    WHEN POSITION('Request Description:' in msg)>0
    THEN  split_part(split_part(sentinel_events.msg::text, ';'::text, 1), ':'::text, 2) END AS request_comment
	
	
   FROM sentinel_events;

ALTER TABLE idm_rpt_data.idmrpt_events_v2
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_events_v2 TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_events_v2 TO idmrptuser;



-- Access-Requests-by-Resource_4.8.6.0-pg-idmrpt_events_v2.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_events_v2 AS 
 SELECT sentinel_events.id AS event_id,
    sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.fn AS filename,
    sentinel_events.rv35 AS init_user_domain,
    sentinel_events.rv45 AS target_user_domain,
    sentinel_events.rv36,
    sentinel_events.rv40,
    sentinel_events.rv43 AS correlation_id,
    sentinel_events.rv47,
    sentinel_events.rv123 AS event_group_id,
    sentinel_events.rv33,
    sentinel_events.rv31,
    sentinel_events.ei AS extended_info,
    sentinel_events.sres AS sub_resource,
    sentinel_events.sev AS severity,
    sentinel_events.res AS resource_name,
    sentinel_events.sip AS init_ip,
    sentinel_events.isvcc AS init_service_comp,
    sentinel_events.iuid AS init_user_id,
    sentinel_events.destassetid AS target_asset_id,
    sentinel_events.dhn AS target_host_name,
    sentinel_events.dip AS target_ip,
    sentinel_events.dip AS target_ip_dotted,
    sentinel_events.ttd AS target_trust_domain,
    sentinel_events.ttn AS target_trust_name,
    sentinel_events.tuid AS target_user_id,
    sentinel_events.xdasid AS taxonomy_id,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name,
    sentinel_events.xdasid AS xdas_taxonomy_id,
    sentinel_events.attr,
	CASE
    WHEN POSITION('Request Description:' in msg)>0
    THEN  split_part(split_part(sentinel_events.msg::text, ';'::text, 1), ':'::text, 2) END AS request_comment
	
	
   FROM sentinel_events;

ALTER TABLE idm_rpt_data.idmrpt_events_v2
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_events_v2 TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_events_v2 TO idmrptuser;



-- Authentication-by-Server_4.8.6.0-pg-idmrpt_auth_by_serv_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_auth_by_serv_v AS 
  SELECT sentinel_events.id event_id,
    sentinel_events.evt event_name,
    sentinel_events.msg base_message,
    sentinel_events.dt event_datetime,
    sentinel_events.ei extended_info,
    sentinel_events.dhn target_host_name,
    sentinel_events.dip target_ip_dotted,
    sentinel_events.agent,
    sentinel_events.xdastaxname xdas_taxonomy_name,
    sentinel_events.xdasoutcomename xdas_outcome_name,
    sentinel_events.sun,
    acct.identity_id,
    sentinel_events.sun target_user_name,
    (sentinel_events.xdastaxname || ' ') || sentinel_events.xdasoutcomename taxonomy_group,
    (identity.first_name || ' ') || identity.last_name targetname,
    ( SELECT DISTINCT (identity.first_name || ' ') || identity.last_name
           FROM sentinel_events sentinel_events_1
             LEFT JOIN idm_rpt_data.idmrpt_idv_acct_cs_v acct2 ON acct2.idv_acct_dn LIKE ((('cn=' || sentinel_events_1.sun) || ',') || '%')
             LEFT JOIN idm_rpt_data.idmrpt_identity_cs_v identity2 ON acct2.identity_id = identity2.identity_id
         FETCH FIRST 1 ROWS ONLY) initname,
    sentinel_events.rv45 target_user_domain
   FROM sentinel_events
     LEFT JOIN idm_rpt_data.idmrpt_idv_acct_cs_v acct ON acct.idv_acct_dn = sentinel_events.sun
     LEFT JOIN idm_rpt_data.idmrpt_identity_cs_v identity ON acct.identity_id = identity.identity_id
  WHERE (sentinel_events.dhn IS NOT NULL OR sentinel_events.dip IS NOT NULL) AND sentinel_events.sun IS NOT NULL 
    AND sentinel_events.xdastaxname = 'XDAS_AE_AUTHENTICATE_ACCOUNT' 
      AND (sentinel_events.xdasoutcomename = 'XDAS_OUT_SUCCESS'
        OR sentinel_events.xdasoutcomename = 'XDAS_OUT_INVALID_USER_CREDENTIALS'
        OR sentinel_events.xdasoutcomename = 'XDAS_OUT_INVALID_IDENTITY')
	  AND sentinel_events.pn = 'Micro Focus One SSO Provider';

ALTER TABLE idm_rpt_data.idmrpt_auth_by_serv_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_auth_by_serv_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_auth_by_serv_v TO idmrptuser;



-- Authentication-by-User_4.8.6.0-pg-idmrpt_auth_by_user_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_auth_by_user_v AS 
 SELECT 
    sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.rv40,
    sentinel_events.ei AS extended_info,
    sentinel_events.dhn AS target_host_name,
    sentinel_events.dip AS target_ip_dotted,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name,
    (sentinel_events.xdastaxname::text || ' '::text) || sentinel_events.xdasoutcomename::text AS taxonomy_group
   FROM sentinel_events

WHERE
(sentinel_events.dhn IS NOT NULL OR sentinel_events.dip IS NOT NULL)
        AND  (sentinel_events.xdastaxname ='XDAS_AE_AUTHENTICATE_ACCOUNT')
        AND (sentinel_events.xdasoutcomename = 'XDAS_OUT_SUCCESS'
                OR sentinel_events.xdasoutcomename = 'XDAS_OUT_INVALID_USER_CREDENTIALS'
                OR sentinel_events.xdasoutcomename = 'XDAS_OUT_INVALID_IDENTITY')
				 AND sentinel_events.pn = 'Micro Focus One SSO Provider';

ALTER TABLE idm_rpt_data.idmrpt_auth_by_user_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_auth_by_user_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_auth_by_user_v TO idmrptuser;




-- Available-Permissions-Current-State_4.8.6.0-pg-idmrpt_prd_summary_cs_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_prd_summary_cs_v AS 
 SELECT idmrpt_idv_prd.idmrpt_valid_from,
    idmrpt_idv_prd.idmrpt_valid_to,
    idmrpt_idv_prd.prd_id,
        CASE
            WHEN btrim(idmrpt_rpt_driver.idv_host::text) = btrim(idmrpt_rpt_driver.idv_name::text) THEN idmrpt_rpt_driver.idv_name::text
            ELSE ((idmrpt_rpt_driver.idv_name::text || ' ('::text) || idmrpt_rpt_driver.idv_host::text) || ')'::text
        END AS idv_name,
        CASE
            WHEN btrim(idmrpt_idv_prd.prd_name::text) = ''::text THEN idmrpt_idv_prd.prd_dn
            ELSE idmrpt_idv_prd.prd_name
        END AS prd_name,
    idmrpt_idv_prd.prd_desc,
    'now'::text::date + 7305 + 'now'::text::time with time zone AS fake_future_date
   FROM idm_rpt_data.idmrpt_rpt_driver_v idmrpt_rpt_driver,
    idm_rpt_data.idmrpt_idv_v idmrpt_idv,
    idm_rpt_data.idmrpt_idv_prd_cs_v idmrpt_idv_prd
  WHERE idmrpt_rpt_driver.idv_id::text = idmrpt_idv.idv_id::text AND idmrpt_idv.idv_id::text = idmrpt_idv_prd.idv_id::text AND
        CASE
            WHEN idmrpt_idv_prd.rpt_drv_id IS NULL THEN 1
            WHEN idmrpt_rpt_driver.rpt_drv_id::text = idmrpt_idv_prd.rpt_drv_id::text THEN 1
            ELSE 0
        END = 1
  ORDER BY (
        CASE
            WHEN btrim(idmrpt_rpt_driver.idv_host::text) = btrim(idmrpt_rpt_driver.idv_name::text) THEN idmrpt_rpt_driver.idv_name::text
            ELSE ((idmrpt_rpt_driver.idv_name::text || ' ('::text) || idmrpt_rpt_driver.idv_host::text) || ')'::text
        END), (
        CASE
            WHEN btrim(idmrpt_idv_prd.prd_name::text) = ''::text THEN idmrpt_idv_prd.prd_dn
            ELSE idmrpt_idv_prd.prd_name
        END), idmrpt_idv_prd.idmrpt_valid_from;

ALTER TABLE idm_rpt_data.idmrpt_prd_summary_cs_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_prd_summary_cs_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_prd_summary_cs_v TO idmrptuser;



-- Available-Permissions-Current-State_4.8.6.0-pg-idmrpt_resources_summary_v.sql

-- View: idm_rpt_data.idmrpt_resources_summary_v

-- DROP VIEW idm_rpt_data.idmrpt_resources_summary_v;

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_resources_summary_v AS 
 SELECT idmrpt_resource.idmrpt_valid_from,
    idmrpt_resource.idmrpt_valid_to,
    idmrpt_resource.res_id,
        CASE
            WHEN btrim(idmrpt_rpt_driver.idv_host::text) = btrim(idmrpt_rpt_driver.idv_name::text) THEN idmrpt_rpt_driver.idv_name::text
            ELSE ((idmrpt_rpt_driver.idv_name::text || ' ('::text) || idmrpt_rpt_driver.idv_host::text) || ')'::text
        END AS idv_name,
        CASE
            WHEN btrim(idmrpt_resource.res_name::text) = ''::text THEN idmrpt_resource.res_dn
            ELSE idmrpt_resource.res_name
        END AS res_name,
    idmrpt_resource.res_desc,
    'now'::text::date + 7305 + 'now'::text::time with time zone AS fake_future_date
   FROM idm_rpt_data.idmrpt_rpt_driver_v idmrpt_rpt_driver,
    idm_rpt_data.idmrpt_idv_v idmrpt_idv,
    idm_rpt_data.idmrpt_resource_cs_v idmrpt_resource
  WHERE idmrpt_rpt_driver.idv_id::text = idmrpt_idv.idv_id::text AND idmrpt_idv.idv_id::text = idmrpt_resource.idv_id::text AND
        CASE
            WHEN idmrpt_resource.rpt_drv_id IS NULL THEN true
            ELSE idmrpt_rpt_driver.rpt_drv_id::text = idmrpt_resource.rpt_drv_id::text
        END
  ORDER BY (
        CASE
            WHEN btrim(idmrpt_rpt_driver.idv_host::text) = btrim(idmrpt_rpt_driver.idv_name::text) THEN idmrpt_rpt_driver.idv_name::text
            ELSE ((idmrpt_rpt_driver.idv_name::text || ' ('::text) || idmrpt_rpt_driver.idv_host::text) || ')'::text
        END), (
        CASE
            WHEN btrim(idmrpt_resource.res_name::text) = ''::text THEN idmrpt_resource.res_dn
            ELSE idmrpt_resource.res_name
        END), idmrpt_resource.idmrpt_valid_from;

ALTER TABLE idm_rpt_data.idmrpt_resources_summary_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_resources_summary_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_resources_summary_v TO idmrptuser;




-- Available-Permissions-Current-State_4.8.6.0-pg-idmrpt_role_cs_summary_v.sql

-- View: idm_rpt_data.idmrpt_role_cs_summary_v

-- DROP VIEW idm_rpt_data.idmrpt_role_cs_summary_v;

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_role_cs_summary_v AS 
 SELECT idmrpt_role.idmrpt_valid_from,
    idmrpt_role.idmrpt_valid_to,
    idmrpt_role.role_id,
        CASE
            WHEN btrim(idmrpt_rpt_driver.idv_host::text) = btrim(idmrpt_rpt_driver.idv_name::text) THEN idmrpt_rpt_driver.idv_name::text
            ELSE ((idmrpt_rpt_driver.idv_name::text || ' ('::text) || idmrpt_rpt_driver.idv_host::text) || ')'::text
        END AS idv_name,
        CASE
            WHEN btrim(idmrpt_role.role_name::text) = ''::text THEN idmrpt_role.role_dn
            ELSE idmrpt_role.role_name
        END AS role_name,
    idmrpt_role.role_desc,
    'now'::text::date + 7305 + 'now'::text::time with time zone AS fake_future_date
   FROM idm_rpt_data.idmrpt_rpt_driver_v idmrpt_rpt_driver,
    idm_rpt_data.idmrpt_idv_v idmrpt_idv,
    idm_rpt_data.idmrpt_role_cs_v idmrpt_role
  WHERE idmrpt_rpt_driver.idv_id::text = idmrpt_idv.idv_id::text AND idmrpt_idv.idv_id::text = idmrpt_role.idv_id::text AND
        CASE
            WHEN idmrpt_role.rpt_drv_id IS NULL THEN true
            ELSE idmrpt_rpt_driver.rpt_drv_id::text = idmrpt_role.rpt_drv_id::text
        END
  ORDER BY (
        CASE
            WHEN btrim(idmrpt_rpt_driver.idv_host::text) = btrim(idmrpt_rpt_driver.idv_name::text) THEN idmrpt_rpt_driver.idv_name::text
            ELSE ((idmrpt_rpt_driver.idv_name::text || ' ('::text) || idmrpt_rpt_driver.idv_host::text) || ')'::text
        END), (
        CASE
            WHEN btrim(idmrpt_role.role_name::text) = ''::text THEN idmrpt_role.role_dn
            ELSE idmrpt_role.role_name
        END), idmrpt_role.idmrpt_valid_from;

ALTER TABLE idm_rpt_data.idmrpt_role_cs_summary_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_role_cs_summary_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_role_cs_summary_v TO idmrptuser;




-- Available-Permissions-Current-State_4.8.6.0-pg-idmrpt_role_res_prd_count_v.sql

-- View: idm_rpt_data.idmrpt_role_res_prd_count_v

-- DROP VIEW idm_rpt_data.idmrpt_role_res_prd_count_v;

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_role_res_prd_count_v AS 
 SELECT ''::text || count(1) AS item_count,
    1 AS "position",
    'Roles'::text AS type,
    roles_dataset_main.idv_name
   FROM ( SELECT idmrpt_role.role_id,
                CASE
                    WHEN btrim(idmrpt_rpt_driver.idv_host) = btrim(idmrpt_rpt_driver.idv_name) THEN idmrpt_rpt_driver.idv_name
                    ELSE ((idmrpt_rpt_driver.idv_name || ' ('::text) || idmrpt_rpt_driver.idv_host) || ')'::text
                END AS idv_name
           FROM idm_rpt_data.idmrpt_rpt_driver_v idmrpt_rpt_driver,
            idm_rpt_data.idmrpt_idv_v idmrpt_idv,
            idm_rpt_data.idmrpt_role_cs_v idmrpt_role
          WHERE idmrpt_rpt_driver.idv_id = idmrpt_idv.idv_id AND idmrpt_idv.idv_id = idmrpt_role.idv_id AND
                CASE
                    WHEN idmrpt_role.rpt_drv_id IS NULL THEN true
                    ELSE idmrpt_rpt_driver.rpt_drv_id = idmrpt_role.rpt_drv_id
                END
          ORDER BY (
                CASE
                    WHEN btrim(idmrpt_rpt_driver.idv_host) = btrim(idmrpt_rpt_driver.idv_name) THEN idmrpt_rpt_driver.idv_name
                    ELSE ((idmrpt_rpt_driver.idv_name || ' ('::text) || idmrpt_rpt_driver.idv_host) || ')'::text
                END), idmrpt_role.role_id) roles_dataset_main
  GROUP BY 'Roles'::text, roles_dataset_main.idv_name
UNION
 SELECT ''::text || count(1) AS item_count,
    2 AS "position",
    'Resources'::text AS type,
    resources_dataset_main.idv_name
   FROM ( SELECT idmrpt_resource.res_id,
                CASE
                    WHEN btrim(idmrpt_rpt_driver.idv_host) = btrim(idmrpt_rpt_driver.idv_name) THEN idmrpt_rpt_driver.idv_name
                    ELSE ((idmrpt_rpt_driver.idv_name || ' ('::text) || idmrpt_rpt_driver.idv_host) || ')'::text
                END AS idv_name
           FROM idm_rpt_data.idmrpt_rpt_driver_v idmrpt_rpt_driver,
            idm_rpt_data.idmrpt_idv_v idmrpt_idv,
            idm_rpt_data.idmrpt_resource_cs_v idmrpt_resource
          WHERE idmrpt_rpt_driver.idv_id = idmrpt_idv.idv_id AND idmrpt_idv.idv_id = idmrpt_resource.idv_id AND
                CASE
                    WHEN idmrpt_resource.rpt_drv_id IS NULL THEN true
                    ELSE idmrpt_rpt_driver.rpt_drv_id = idmrpt_resource.rpt_drv_id
                END
          ORDER BY (
                CASE
                    WHEN btrim(idmrpt_rpt_driver.idv_host) = btrim(idmrpt_rpt_driver.idv_name) THEN idmrpt_rpt_driver.idv_name
                    ELSE ((idmrpt_rpt_driver.idv_name || ' ('::text) || idmrpt_rpt_driver.idv_host) || ')'::text
                END), idmrpt_resource.res_id) resources_dataset_main
  GROUP BY 'Resources'::text, resources_dataset_main.idv_name
UNION
 SELECT ''::text || count(1) AS item_count,
    3 AS "position",
    'Provisioning Request Definitions'::text AS type,
    prds_dataset_main.idv_name
   FROM ( SELECT idmrpt_idv_prd.prd_id,
                CASE
                    WHEN btrim(idmrpt_rpt_driver.idv_host) = btrim(idmrpt_rpt_driver.idv_name) THEN idmrpt_rpt_driver.idv_name
                    ELSE ((idmrpt_rpt_driver.idv_name || ' ('::text) || idmrpt_rpt_driver.idv_host) || ')'::text
                END AS idv_name
           FROM idm_rpt_data.idmrpt_rpt_driver_v idmrpt_rpt_driver,
            idm_rpt_data.idmrpt_idv_v idmrpt_idv,
            idm_rpt_data.idmrpt_idv_prd_cs_v idmrpt_idv_prd
          WHERE idmrpt_rpt_driver.idv_id = idmrpt_idv.idv_id AND idmrpt_idv.idv_id = idmrpt_idv_prd.idv_id AND
                CASE
                    WHEN idmrpt_idv_prd.rpt_drv_id IS NULL THEN true
                    ELSE idmrpt_rpt_driver.rpt_drv_id = idmrpt_idv_prd.rpt_drv_id
                END
          ORDER BY (
                CASE
                    WHEN btrim(idmrpt_rpt_driver.idv_host) = btrim(idmrpt_rpt_driver.idv_name) THEN idmrpt_rpt_driver.idv_name
                    ELSE ((idmrpt_rpt_driver.idv_name || ' ('::text) || idmrpt_rpt_driver.idv_host) || ')'::text
                END), idmrpt_idv_prd.prd_id) prds_dataset_main
  GROUP BY 'Provisioning Request Definitions'::text, prds_dataset_main.idv_name;

ALTER TABLE idm_rpt_data.idmrpt_role_res_prd_count_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_role_res_prd_count_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_role_res_prd_count_v TO idmrptuser;




-- Correlated-Resource-Assignment-Events-by-User_4.8.6.0-pg-idmrpt_corr_res_assignment_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_corr_res_assignment_v AS 
 SELECT sentinel_events.id AS event_id,
    sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.fn AS filename,
    sentinel_events.rv45,
    sentinel_events.rv36,
    sentinel_events.rv43,
    sentinel_events.ei AS extended_info,
    sentinel_events.iuid AS init_user_id,
    sentinel_events.agent,
        CASE
            WHEN sentinel_events.agent::text ~~ (('%'::text || 'NetIQ Modular Authentication Services'::text) || '%'::text) THEN
            CASE
                WHEN sentinel_events.evt::text ~~ '%LSM%'::text THEN ((('\'::text || rtrim("substring"("substring"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), 0, "position"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), ','::text) - 1), "position"("substring"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), 0, "position"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), ','::text) - 1), '.O='::text) + 3), ' '::text)) || '\'::text) || "substring"("substring"("substring"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), 0, "position"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), ','::text) - 1), "position"("substring"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), 0, "position"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), ','::text) - 1), 'OU='::text) + 3), 0, "position"("substring"("substring"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), 0, "position"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), ','::text) - 1), "position"("substring"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), 0, "position"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), ','::text) - 1), 'OU='::text) + 3), '.O='::text)))::character varying
                ELSE sentinel_events.rv36
            END
            ELSE
            CASE
                WHEN sentinel_events.rv45 IS NULL THEN sentinel_events.rv36
                ELSE
                CASE
                    WHEN sentinel_events.rv45::text ~~ ('%cn=%'::text || 'o=%'::text) THEN ((('\'::text || split_part(sentinel_events.rv45::text, '='::text, 4)) || '\'::text) || split_part(split_part(sentinel_events.rv45::text, ','::text, 2), '='::text, 2))::character varying
                    ELSE sentinel_events.rv45
                END
            END
        END AS target_user_domain,
    COALESCE(sentinel_events.iuid, sentinel_events.sun) AS acting_identity,
    split_part(split_part(sentinel_events.msg::text, 'Correlation ID: '::text, 2), ';'::text, 1) AS correlation_id,
	CASE
    WHEN POSITION('Source DN:' in sentinel_events.msg)>0
	THEN
	split_part(SUBSTRING(split_part(sentinel_events.msg::text, 'Request DN:'::text, 1),POSITION('Source DN:' in (split_part(sentinel_events.msg::text, 'Request DN:'::text, 1)) )+10,(LENGTH((split_part(sentinel_events.msg::text, 'Request DN:'::text, 1)))- POSITION('Source DN:' in (split_part(sentinel_events.msg::text, 'Request DN:'::text, 1))))),';'::text,1)
     END 	AS resource_msg
   FROM sentinel_events;

ALTER TABLE idm_rpt_data.idmrpt_corr_res_assignment_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_corr_res_assignment_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_corr_res_assignment_v TO idmrptuser;




-- Database-Statistics_4.8.6.0-pg-idmrpt_events_v2.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_events_v2 AS 
 SELECT sentinel_events.id AS event_id,
    sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.fn AS filename,
    sentinel_events.rv35 AS init_user_domain,
    sentinel_events.rv45 AS target_user_domain,
    sentinel_events.rv36,
    sentinel_events.rv40,
    sentinel_events.rv43 AS correlation_id,
    sentinel_events.rv47,
    sentinel_events.rv123 AS event_group_id,
    sentinel_events.rv33,
    sentinel_events.rv31,
    sentinel_events.ei AS extended_info,
    sentinel_events.sres AS sub_resource,
    sentinel_events.sev AS severity,
    sentinel_events.res AS resource_name,
    sentinel_events.sip AS init_ip,
    sentinel_events.isvcc AS init_service_comp,
    sentinel_events.iuid AS init_user_id,
    sentinel_events.destassetid AS target_asset_id,
    sentinel_events.dhn AS target_host_name,
    sentinel_events.dip AS target_ip,
    sentinel_events.dip AS target_ip_dotted,
    sentinel_events.ttd AS target_trust_domain,
    sentinel_events.ttn AS target_trust_name,
    sentinel_events.tuid AS target_user_id,
    sentinel_events.xdasid AS taxonomy_id,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name,
    sentinel_events.xdasid AS xdas_taxonomy_id,
    sentinel_events.attr,
	CASE
    WHEN POSITION('Request Description:' in msg)>0
    THEN  split_part(split_part(sentinel_events.msg::text, ';'::text, 1), ':'::text, 2) END AS request_comment
	
	
   FROM sentinel_events;

ALTER TABLE idm_rpt_data.idmrpt_events_v2
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_events_v2 TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_events_v2 TO idmrptuser;



-- Database-Statistics_4.8.6.0-pg-idmrpt_system_info_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_system_info_v AS 
 SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    pg_total_relation_size(c.oid::regclass)::numeric / (1024::numeric * 1024.0) AS size,
    c.reltuples AS rows_estimated,
    GREATEST(s.last_analyze, s.last_autoanalyze) AS analyzed,
    pg_database_size(current_database())::numeric / (1024::numeric * 1024.0) AS total_db_size
   FROM pg_class c
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     LEFT JOIN pg_stat_all_tables s ON s.relid = c.oid
  WHERE c.relkind = 'r'::"char" AND (n.nspname = ANY (ARRAY['idm_rpt_data'::name, 'idm_rpt_data'::name])) AND (pg_total_relation_size(c.oid::regclass) >= 65536 OR c.reltuples > 0::double precision)
  ORDER BY n.nspname, c.relname;

ALTER TABLE idm_rpt_data.idmrpt_system_info_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_system_info_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_system_info_v TO idmrptuser;




-- Identity-Vault-User-Report_4.8.6.0-pg-idmrpt_identity_photo_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_identity_photo_v AS 
 SELECT idmrpt_identity.identity_id,
    idmrpt_identity.photo
   FROM idm_rpt_data.idmrpt_identity idmrpt_identity;

ALTER TABLE idm_rpt_data.idmrpt_identity_photo_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_identity_photo_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_identity_photo_v TO idmrptuser;



-- Identity-Vault-User-Report-Current-State_4.8.6.0-pg-idmrpt_identity_info_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_identity_info_v AS 
 SELECT DISTINCT idmrpt_identity.identity_id,
    idmrpt_identity.job_title,
    idmrpt_identity.department,
    idmrpt_identity.department_number,
    idmrpt_identity.job_code,
    idmrpt_identity.workforce_id,
    idmrpt_identity.employee_status,
    idmrpt_identity.employee_type,
    idmrpt_identity.manager_workforce_id,
    idmrpt_identity.company,
    idmrpt_identity.location,
    idmrpt_identity.cost_center,
    idmrpt_identity.cost_center_description,
    idmrpt_identity.email_address,
    idmrpt_identity.office_phone,
    idmrpt_identity.office_number,
    idmrpt_identity.cell_phone,
    idmrpt_identity.private_phone,
    idmrpt_identity.fax_number,
    idmrpt_identity.im_id,
    idmrpt_identity.pager_number,
    idmrpt_identity.preferred_name,
    idmrpt_identity.preferred_language,
    idmrpt_identity.generational_qualifier,
    idmrpt_identity.prefix,
    idmrpt_identity.mailstop,
    idmrpt_identity.street_address,
    idmrpt_identity.city,
    idmrpt_identity.postal_code,
    idmrpt_identity.state,
    idmrpt_identity.country,
    idmrpt_identity.hire_date,
    idmrpt_identity.transfer_date,
    idmrpt_identity.termination_date,
    idmrpt_identity.first_working_day,
    idmrpt_identity.last_working_day,
    idmrpt_identity.identity_desc,
    idmrpt_identity.idmrpt_valid_from AS identity_valid_from,
    idmrpt_identity.idmrpt_valid_to AS identity_valid_to,
    'now'::text::date + 7305 + 'now'::text::time with time zone AS fake_future_date,
    idmrpt_identity.middle_initial,
    idmrpt_identity.first_name,
    idmrpt_identity.last_name,
    idmrpt_identity.photo,
    idmrpt_idv_acct.idmrpt_valid_from,
    idmrpt_idv_acct.idmrpt_valid_to,
    idmrpt_rpt_driver.idv_name,
    idmrpt_rpt_driver.idv_host,
    idmrpt_idv_acct.idv_acct_dn,
    idmrpt_idv_acct.idv_acct_status
   FROM idm_rpt_data.idmrpt_identity_cs_v idmrpt_identity
     LEFT JOIN idm_rpt_data.idmrpt_identity_cs_v idmrpt_identity_mgr ON idmrpt_identity_mgr.identity_id::text = idmrpt_identity.mgr_id::text
     LEFT JOIN idm_rpt_data.idmrpt_idv_acct_cs_v idmrpt_idv_acct ON idmrpt_identity.identity_id::text = idmrpt_idv_acct.identity_id::text AND idmrpt_idv_acct.idmrpt_deleted = false
     LEFT JOIN idm_rpt_data.idmrpt_idv_v idmrpt_idv ON idmrpt_idv_acct.idv_id::text = idmrpt_idv.idv_id::text
     LEFT JOIN idm_rpt_data.idmrpt_rpt_driver_v idmrpt_rpt_driver ON idmrpt_rpt_driver.idv_id::text = idmrpt_idv.idv_id::text AND
        CASE
            WHEN idmrpt_idv_acct.rpt_drv_id IS NOT NULL THEN idmrpt_rpt_driver.rpt_drv_id::text = idmrpt_idv_acct.rpt_drv_id::text
            ELSE NULL::boolean
        END;

ALTER TABLE idm_rpt_data.idmrpt_identity_info_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_identity_info_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_identity_info_v TO idmrptuser;




-- Identity-Vault-User-Report-Current-State_4.8.6.0-pg-idmrpt_identity_photo_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_identity_photo_v AS 
 SELECT idmrpt_identity.identity_id,
    idmrpt_identity.photo
   FROM idm_rpt_data.idmrpt_identity idmrpt_identity;

ALTER TABLE idm_rpt_data.idmrpt_identity_photo_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_identity_photo_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_identity_photo_v TO idmrptuser;



-- Object-Provisioning_4.8.6.0-pg-idmrpt_object_prov_v.sql

-- View: idm_rpt_data.idmrpt_object_prov_v

-- DROP VIEW idm_rpt_data.idmrpt_object_prov_v;

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_object_prov_v AS 
 SELECT sentinel_events.id AS event_id,
    sentinel_events.evt AS event_name,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.fn AS filename,
    sentinel_events.rv36,
    sentinel_events.isvcc AS init_service_comp,
    sentinel_events.iuid AS init_user_id,
    sentinel_events.dhn AS target_host_name,
    sentinel_events.dip AS target_ip_dotted,
    sentinel_events.ttd AS target_trust_domain,
    sentinel_events.ttn AS target_trust_name,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name,
    (sentinel_events.xdastaxname::text || ' '::text) || sentinel_events.xdasoutcomename::text AS taxonomy_group
   FROM sentinel_events
  WHERE NOT (sentinel_events.fn IS NULL AND sentinel_events.dun IS NULL AND sentinel_events.ttn IS NULL) AND (sentinel_events.agent::text ~~ (('%'::text || 'Identity Manager'::text) || '%'::text) OR sentinel_events.agent::text ~~ (('%'::text || 'Modular Authentication Services'::text) || '%'::text) OR sentinel_events.agent::text ~~ (('%'::text || 'iManager'::text) || '%'::text) OR sentinel_events.agent::text ~~ (('%'::text || 'Universal Common Event Format'::text) || '%'::text) OR sentinel_events.agent::text ~~ (('%'::text || 'NetIQ universal collector'::text) || '%'::text)) AND (sentinel_events.xdastaxname::text = 'XDAS_AE_ASSOC_TRUST'::text OR sentinel_events.xdastaxname::text = 'XDAS_AE_GRANT_ACCOUNT_ACCESS'::text OR sentinel_events.xdastaxname::text = 'XDAS_AE_REVOKE_ACCOUNT_ACCESS'::text OR sentinel_events.xdastaxname::text = 'XDAS_AE_DEASSOC_TRUST'::text) AND (sentinel_events.xdasoutcomename::text = 'XDAS_OUT_SUCCESS'::text OR sentinel_events.xdasoutcomename::text = 'XDAS_OUT_FAILURE'::text) AND NOT sentinel_events.rv43 IS NULL;

ALTER TABLE idm_rpt_data.idmrpt_object_prov_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_object_prov_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_object_prov_v TO idmrptuser;




-- Password-Resets_4.8.6.0-pg-idmrpt_pass_reset_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_pass_reset_v AS 
 SELECT sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    CASE WHEN sentinel_events.sun IS NULL THEN sentinel_events.iuid ELSE sentinel_events.sun END AS source_user_name,
        CASE
            WHEN sentinel_events.agent::text ~~ (('%'::text || 'NetIQ Modular Authentication Services'::text) || '%'::text) THEN
            CASE
                WHEN sentinel_events.evt::text ~~ '%LSM%'::text THEN "substring"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), "position"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), 'CN='::text) + 3, "position"("substring"(sentinel_events.ei::text, "position"(sentinel_events.ei::text, 'Target:'::text) + 12), '.OU'::text) - 4)::character varying
                ELSE sentinel_events.fn
            END
            ELSE
            CASE
                WHEN sentinel_events.dun IS NULL THEN
                CASE
                    WHEN sentinel_events.sun IS NULL THEN sentinel_events.iuid
                    ELSE sentinel_events.sun
                END
                ELSE sentinel_events.dun
            END
        END AS destination_user_name,
        CASE
            WHEN sentinel_events.rv35 IS NULL THEN sentinel_events.rv36
            ELSE
            CASE
                WHEN sentinel_events.rv35::text ~~ ('%cn=%'::text || 'o=%'::text) THEN ((('\'::text || split_part(sentinel_events.rv35::text, '='::text, 4)) || '\'::text) || split_part(split_part(sentinel_events.rv35::text, ','::text, 2), '='::text, 2))::character varying
                ELSE sentinel_events.rv35
            END
        END AS user_domain,
    (sentinel_events.xdastaxname::text || ' '::text) || sentinel_events.xdasoutcomename::text AS taxonomy_group,
    sentinel_events.fn AS filename,
    sentinel_events.rv45 AS target_user_domain,
    sentinel_events.rv36,
    sentinel_events.ei AS extended_info,
    sentinel_events.tuid AS target_user_id,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name
   FROM sentinel_events
  WHERE
        CASE
            WHEN (sentinel_events.agent::text ~~ (('%'::text || 'Identity Manager'::text) || '%'::text) OR sentinel_events.agent::text ~~ (('%'::text || 'Universal Common Event Format'::text) || '%'::text)) THEN sentinel_events.rv45 IS NOT NULL
            ELSE 1 = 1
        END AND sentinel_events.xdastaxname::text = 'XDAS_AE_SET_CRED_ACCOUNT'::text AND (sentinel_events.xdasoutcomename::text = 'XDAS_OUT_SUCCESS'::text OR sentinel_events.xdasoutcomename::text = 'XDAS_OUT_FAILURE'::text);

ALTER TABLE idm_rpt_data.idmrpt_pass_reset_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_pass_reset_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_pass_reset_v TO idmrptuser;




-- Resource-Assignments-by-Resource_4.8.6.0-pg-idmrpt_res_approvals_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_res_approvals_v AS 
 SELECT DISTINCT approver.identity_id AS approver_id,
    approver.first_name,
    approver.middle_initial,
    approver.last_name,
    approval.approval_type,
    approval.action,
    approval.approval_date,
    approval.item_id,
    approval.identity_id AS approval_id,
    approver.idmrpt_valid_to AS approver_idmrpt_valid_to
   FROM idm_rpt_data.idmrpt_identity_v approver,
    idm_rpt_data.idmrpt_approval_v approval
  WHERE approver.identity_id::text = approval.identity_id::text
  ORDER BY approval.approval_date;

ALTER TABLE idm_rpt_data.idmrpt_res_approvals_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_res_approvals_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_res_approvals_v TO idmrptuser;



-- Resource-Assignments-by-Resource-Current-State_4.8.6.0-pg-idmrpt_approver_approval_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_approver_approval_v AS 
 SELECT DISTINCT approver.identity_id AS approver_id,
    approver.first_name,
    approver.middle_initial,
    approver.last_name,
    approver.idmrpt_valid_to AS approver_idmrpt_valid_to,
    approver.idmrpt_valid_from AS approver_idmrpt_valid_from,
    approval.approval_type,
    approval.action,
    approval.approval_date,
    approval.item_id,
    approval.identity_id AS approval_id,
    approval.idmrpt_valid_to AS approval_idmrpt_valid_to,
    approval.idmrpt_valid_from AS approval_idmrpt_valid_from
   FROM idm_rpt_data.idmrpt_identity_v approver,
    idm_rpt_data.idmrpt_approval_v approval
  WHERE approver.identity_id::text = approval.identity_id::text
  ORDER BY approval.approval_date;

ALTER TABLE idm_rpt_data.idmrpt_approver_approval_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_approver_approval_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_approver_approval_v TO idmrptuser;




-- Resource-Assignments-by-Resource-Current-State_4.8.6.0-pg-idmrpt_resource_info_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_resource_info_v AS 
 SELECT DISTINCT ON ((COALESCE(idmrpt_resource.res_name, idmrpt_resource.res_dn)), (
        CASE
            WHEN lower(idmrpt_idv_identity_trust.cause_type::text) = lower('role driver'::text) THEN (rela.role_name::text || ' -- '::text) || rela.role_descr::text
            ELSE NULL::text
        END), idmrpt_idv_identity_trust.trust_start_time, idmrpt_idv_identity_trust.idmrpt_valid_to, driver.drv_name, (
        CASE
            WHEN binding.ent_param_str::text ~~ '%ID2%'::text THEN ( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
               FROM idm_rpt_data.idmrpt_ms_ent_cs_v
              WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID2'::text) + 6, "position"("substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID2'::text) + 6), '}'::text) - 2))
            WHEN binding.ent_param_str::text ~~ '%ID%'::text THEN ( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
               FROM idm_rpt_data.idmrpt_ms_ent_cs_v
              WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID'::text) + 5, "position"("substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID'::text) + 5), '}'::text) - 2))
            WHEN binding.ent_param_str::text = '%EntitlementParamKey%'::text OR binding.ent_param_val::text = '%EntitlementParamKey%'::text THEN
            CASE
                WHEN idmrpt_idv_identity_trust.trust_params::text ~~ '%ID2%'::text THEN (( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
                   FROM idm_rpt_data.idmrpt_ms_ent_cs_v
                  WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID2'::text) + 6, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID2'::text) + 6), '}'::text) - 2)))::text
                WHEN idmrpt_idv_identity_trust.trust_params::text ~~ '%ID%'::text THEN (( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
                   FROM idm_rpt_data.idmrpt_ms_ent_cs_v
                  WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID'::text) + 5, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID'::text) + 5), '}'::text) - 2)))::text
                ELSE "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'EntitlementParamKey'::text) + 21, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'EntitlementParamKey'::text) + 21), '</value>'::text) - 1)
            END::character varying
            ELSE binding.ent_param_val
        END), binding.ent_param_liid) idmrpt_resource.res_id,
    COALESCE(idmrpt_resource.res_name, idmrpt_resource.res_dn) AS res_name,
    idmrpt_resource.res_dn,
    idmrpt_resource.res_desc,
    idmrpt_resource.idmrpt_syn_state,
        CASE
            WHEN lower(idmrpt_idv_identity_trust.cause_type::text) = lower('role driver'::text) THEN (rela.role_name::text || ' -- '::text) || rela.role_descr::text
            ELSE NULL::text
        END AS role_name,
        CASE
            WHEN btrim(idmrpt_rpt_driver.idv_host::text) = btrim(idmrpt_rpt_driver.idv_name::text) THEN idmrpt_rpt_driver.idv_name::text
            ELSE ((idmrpt_rpt_driver.idv_name::text || ' ('::text) || idmrpt_rpt_driver.idv_host::text) || ')'::text
        END AS idv_name1,
    idmrpt_identity.last_name,
    idmrpt_identity.first_name,
    idmrpt_identity.middle_initial,
    idmrpt_idv_identity_trust.trust_start_time,
    idmrpt_idv_identity_trust.trust_expiration_time,
    idmrpt_idv_identity_trust.idmrpt_valid_to,
    idmrpt_idv_identity_trust.identity_id,
    idmrpt_idv_identity_trust.requester_id,
    idmrpt_idv_identity_trust.trust_id,
    idmrpt_idv_identity_trust.trust_type_id,
    idmrpt_idv_identity_trust.idmrpt_deleted AS idm_rpt_deleted,
    idmrpt_idv_identity_trust.idv_ent_ref,
    ent.idmrpt_ent_dn AS ent_dn,
    ent.idmrpt_ent_name AS ent_name,
    driver.drv_dn AS driver_dn,
    driver.drv_name AS driver_name,
    'now'::text::date + 7305 + 'now'::text::time with time zone AS fake_future_date,
        CASE
            WHEN binding.ent_param_str::text ~~ '%ID2%'::text THEN ( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
               FROM idm_rpt_data.idmrpt_ms_ent_cs_v
              WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID2'::text) + 6, "position"("substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID2'::text) + 6), '}'::text) - 2))
            WHEN binding.ent_param_str::text ~~ '%ID%'::text THEN ( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
               FROM idm_rpt_data.idmrpt_ms_ent_cs_v
              WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID'::text) + 5, "position"("substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID'::text) + 5), '}'::text) - 2))
            WHEN binding.ent_param_str::text = '%EntitlementParamKey%'::text OR binding.ent_param_val::text = '%EntitlementParamKey%'::text THEN
            CASE
                WHEN idmrpt_idv_identity_trust.trust_params::text ~~ '%ID2%'::text THEN (( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
                   FROM idm_rpt_data.idmrpt_ms_ent_cs_v
                  WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID2'::text) + 6, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID2'::text) + 6), '}'::text) - 2)))::text
                WHEN idmrpt_idv_identity_trust.trust_params::text ~~ '%ID%'::text THEN (( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
                   FROM idm_rpt_data.idmrpt_ms_ent_cs_v
                  WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID'::text) + 5, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID'::text) + 5), '}'::text) - 2)))::text
                ELSE "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'EntitlementParamKey'::text) + 21, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'EntitlementParamKey'::text) + 21), '</value>'::text) - 1)
            END::character varying
            ELSE binding.ent_param_val
        END AS ent_value,
    ent.idv_ent_id,
    binding.ent_param_liid AS liid
   FROM idm_rpt_data.idmrpt_rpt_driver_v idmrpt_rpt_driver,
    idm_rpt_data.idmrpt_idv_v idmrpt_idv,
    idm_rpt_data.idmrpt_identity_cs_v idmrpt_identity,
    idm_rpt_data.idmrpt_idv_identity_trust_cs_v idmrpt_idv_identity_trust,
    idm_rpt_data.idmrpt_resource_cs_v idmrpt_resource
     LEFT JOIN idm_rpt_data.idmrpt_idv_ent_bindings_cs_v binding ON binding.cat_item_id::text = idmrpt_resource.res_id::text
     LEFT JOIN idm_rpt_data.idmrpt_idv_ent_cs_v ent ON binding.ent_id::text = ent.idv_ent_id::text
     LEFT JOIN idm_rpt_data.idmrpt_idv_drivers_cs_v driver ON ent.idv_driver_id::text = driver.idv_driver_id::text
     LEFT JOIN idm_rpt_data.idmrpt_r_to_res_relationship_v rela ON idmrpt_resource.res_id::text = rela.res_id::text
  WHERE idmrpt_resource.res_id::text = idmrpt_idv_identity_trust.trust_obj_id::text AND idmrpt_rpt_driver.idv_id::text = idmrpt_idv.idv_id::text AND
        CASE
            WHEN idmrpt_resource.rpt_drv_id IS NULL THEN idmrpt_resource.rpt_drv_id IS NULL
            ELSE idmrpt_rpt_driver.rpt_drv_id::text = idmrpt_resource.rpt_drv_id::text
        END AND idmrpt_idv.idv_id::text = idmrpt_resource.idv_id::text AND idmrpt_idv_identity_trust.identity_id::text = idmrpt_identity.identity_id::text AND
        CASE
            WHEN lower(idmrpt_idv_identity_trust.cause_type::text) = lower('role driver'::text) THEN (( SELECT count(1) AS count
               FROM idm_rpt_data.idmrpt_idv_identity_trust_v identity_trust
              WHERE identity_trust.trust_obj_id::text = rela.role_id::text AND identity_trust.identity_id::text = idmrpt_idv_identity_trust.identity_id::text)) > 0
            ELSE 1 = 1
        END
  ORDER BY (COALESCE(idmrpt_resource.res_name, idmrpt_resource.res_dn)), (
        CASE
            WHEN lower(idmrpt_idv_identity_trust.cause_type::text) = lower('role driver'::text) THEN (rela.role_name::text || ' -- '::text) || rela.role_descr::text
            ELSE NULL::text
        END), idmrpt_idv_identity_trust.trust_start_time, idmrpt_idv_identity_trust.idmrpt_valid_to, driver.drv_name, (
        CASE
            WHEN binding.ent_param_str::text ~~ '%ID2%'::text THEN ( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
               FROM idm_rpt_data.idmrpt_ms_ent_cs_v
              WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID2'::text) + 6, "position"("substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID2'::text) + 6), '}'::text) - 2))
            WHEN binding.ent_param_str::text ~~ '%ID%'::text THEN ( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
               FROM idm_rpt_data.idmrpt_ms_ent_cs_v
              WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID'::text) + 5, "position"("substring"(binding.ent_param_str::text, "position"(binding.ent_param_str::text, 'ID'::text) + 5), '}'::text) - 2))
            WHEN binding.ent_param_str::text = '%EntitlementParamKey%'::text OR binding.ent_param_val::text = '%EntitlementParamKey%'::text THEN
            CASE
                WHEN idmrpt_idv_identity_trust.trust_params::text ~~ '%ID2%'::text THEN (( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
                   FROM idm_rpt_data.idmrpt_ms_ent_cs_v
                  WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID2'::text) + 6, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID2'::text) + 6), '}'::text) - 2)))::text
                WHEN idmrpt_idv_identity_trust.trust_params::text ~~ '%ID%'::text THEN (( SELECT idmrpt_ms_ent_cs_v.ms_ent_val_disp_name
                   FROM idm_rpt_data.idmrpt_ms_ent_cs_v
                  WHERE idmrpt_ms_ent_cs_v.ms_ent_val::text = "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID'::text) + 5, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'ID'::text) + 5), '}'::text) - 2)))::text
                ELSE "substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'EntitlementParamKey'::text) + 21, "position"("substring"(idmrpt_idv_identity_trust.trust_params::text, "position"(idmrpt_idv_identity_trust.trust_params::text, 'EntitlementParamKey'::text) + 21), '</value>'::text) - 1)
            END::character varying
            ELSE binding.ent_param_val
        END), binding.ent_param_liid, idmrpt_identity.last_name, idmrpt_identity.first_name, idmrpt_identity.middle_initial;

ALTER TABLE idm_rpt_data.idmrpt_resource_info_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_resource_info_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_resource_info_v TO idmrptuser;




-- Self-Password-Changes_4.8.6.0-pg-idmrpt_self_pass_change_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_self_pass_change_v AS 
SELECT sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
        CASE
            WHEN sentinel_events.dun IS NULL THEN
            CASE
                WHEN sentinel_events.sun IS NULL THEN sentinel_events.iuid
                ELSE sentinel_events.sun
            END
            ELSE sentinel_events.dun
        END AS target_user_name,
    identity.last_name,
    identity.first_name,
    identity.department,
    acct.identity_id,
    sentinel_events.rv35,
        CASE
            WHEN sentinel_events.rv35 IS NULL THEN sentinel_events.rv36
            ELSE
            CASE
                WHEN sentinel_events.rv35::text ~~ ('%cn=%'::text || 'o=%'::text) THEN ((('\'::text || split_part(sentinel_events.rv35::text, '='::text, 4)) || '\'::text) || split_part(split_part(sentinel_events.rv35::text, ','::text, 2), '='::text, 2))::character varying
                ELSE sentinel_events.rv35
            END
        END AS user_domain,
    sentinel_events.rv36,
    (sentinel_events.xdastaxname::text || ' '::text) || sentinel_events.xdasoutcomename::text AS taxonomy_group,
    sentinel_events.rv40,
    sentinel_events.ei AS extended_info,
    sentinel_events.sip AS init_ip,
    sentinel_events.tuid AS target_user_id,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name
   FROM sentinel_events
     LEFT OUTER JOIN idm_rpt_data.idmrpt_idv_acct_cs_v acct ON acct.idv_acct_dn LIKE ('%' || sentinel_events.msg || '%')
    LEFT OUTER JOIN idm_rpt_data.idmrpt_identity_cs_v identity ON acct.identity_id = identity.identity_id
  WHERE
  sentinel_events.agent LIKE ('%' || 'Password Reset' || '%')
  AND sentinel_events.xdastaxname= 'XDAS_AE_SET_CRED_ACCOUNT';

ALTER TABLE idm_rpt_data.idmrpt_self_pass_change_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_self_pass_change_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_self_pass_change_v TO idmrptuser; 



-- User-Entitlements_4.8.6.0-pg-idmrpt_events_v2.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_events_v2 AS 
 SELECT sentinel_events.id AS event_id,
    sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.fn AS filename,
    sentinel_events.rv35 AS init_user_domain,
    sentinel_events.rv45 AS target_user_domain,
    sentinel_events.rv36,
    sentinel_events.rv40,
    sentinel_events.rv43 AS correlation_id,
    sentinel_events.rv47,
    sentinel_events.rv123 AS event_group_id,
    sentinel_events.rv33,
    sentinel_events.rv31,
    sentinel_events.ei AS extended_info,
    sentinel_events.sres AS sub_resource,
    sentinel_events.sev AS severity,
    sentinel_events.res AS resource_name,
    sentinel_events.sip AS init_ip,
    sentinel_events.isvcc AS init_service_comp,
    sentinel_events.iuid AS init_user_id,
    sentinel_events.destassetid AS target_asset_id,
    sentinel_events.dhn AS target_host_name,
    sentinel_events.dip AS target_ip,
    sentinel_events.dip AS target_ip_dotted,
    sentinel_events.ttd AS target_trust_domain,
    sentinel_events.ttn AS target_trust_name,
    sentinel_events.tuid AS target_user_id,
    sentinel_events.xdasid AS taxonomy_id,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name,
    sentinel_events.xdasid AS xdas_taxonomy_id,
    sentinel_events.attr,
	CASE
    WHEN POSITION('Request Description:' in msg)>0
    THEN  split_part(split_part(sentinel_events.msg::text, ';'::text, 1), ':'::text, 2) END AS request_comment
	
	
   FROM sentinel_events;

ALTER TABLE idm_rpt_data.idmrpt_events_v2
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_events_v2 TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_events_v2 TO idmrptuser;



-- User-Password-Change-Events-Summary_4.8.6.0-pg-idmrpt_events_v2.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_events_v2 AS 
 SELECT sentinel_events.id AS event_id,
    sentinel_events.evt AS event_name,
    sentinel_events.msg AS base_message,
    sentinel_events.dt AS event_datetime,
    sentinel_events.sun AS source_user_name,
    sentinel_events.dun AS destination_user_name,
    sentinel_events.fn AS filename,
    sentinel_events.rv35 AS init_user_domain,
    sentinel_events.rv45 AS target_user_domain,
    sentinel_events.rv36,
    sentinel_events.rv40,
    sentinel_events.rv43 AS correlation_id,
    sentinel_events.rv47,
    sentinel_events.rv123 AS event_group_id,
    sentinel_events.rv33,
    sentinel_events.rv31,
    sentinel_events.ei AS extended_info,
    sentinel_events.sres AS sub_resource,
    sentinel_events.sev AS severity,
    sentinel_events.res AS resource_name,
    sentinel_events.sip AS init_ip,
    sentinel_events.isvcc AS init_service_comp,
    sentinel_events.iuid AS init_user_id,
    sentinel_events.destassetid AS target_asset_id,
    sentinel_events.dhn AS target_host_name,
    sentinel_events.dip AS target_ip,
    sentinel_events.dip AS target_ip_dotted,
    sentinel_events.ttd AS target_trust_domain,
    sentinel_events.ttn AS target_trust_name,
    sentinel_events.tuid AS target_user_id,
    sentinel_events.xdasid AS taxonomy_id,
    sentinel_events.agent,
    sentinel_events.xdastaxname AS xdas_taxonomy_name,
    sentinel_events.xdasoutcomename AS xdas_outcome_name,
    sentinel_events.xdasid AS xdas_taxonomy_id,
    sentinel_events.attr,
	CASE
    WHEN POSITION('Request Description:' in msg)>0
    THEN  split_part(split_part(sentinel_events.msg::text, ';'::text, 1), ':'::text, 2) END  AS request_comment
	
	
   FROM sentinel_events;

ALTER TABLE idm_rpt_data.idmrpt_events_v2
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_events_v2 TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_events_v2 TO idmrptuser;



-- User-Password-Change-Events-Summary_4.8.6.0-pg-idmrpt_password_summary_v.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_password_summary_v AS 
 SELECT DISTINCT events.event_datetime AS event_parse_time,
    events.source_user_name AS init_user_name,
        CASE
            WHEN events.destination_user_name IS NULL THEN
            CASE
                WHEN events.source_user_name IS NULL THEN events.init_user_id
                ELSE events.source_user_name
            END
            ELSE events.destination_user_name
        END AS target_user_name,
        CASE
            WHEN events.init_user_domain IS NULL THEN events.rv36
            ELSE
            CASE
                WHEN events.init_user_domain::text ~~ ('%cn=%'::text || 'o=%'::text) THEN ((('\'::text || split_part(events.init_user_domain::text, '='::text, 4)) || '\'::text) || split_part(split_part(events.init_user_domain::text, ','::text, 2), '='::text, 2))::character varying
                ELSE events.target_user_domain
            END
        END AS target_user_domain,
    'Password changes'::text AS password_group,
    events.event_datetime AS eventtime_day,
    events.event_datetime AS eventtime_hour,
        CASE
            WHEN events.xdas_outcome_name::text = 'XDAS_OUT_SUCCESS'::text THEN 1
            ELSE 0
        END AS successcnt,
        CASE
            WHEN events.xdas_outcome_name::text = 'XDAS_OUT_FAILURE'::text THEN 1
            ELSE 0
        END AS failurecnt,
    1 AS cnt,
    events.event_name,
    events.xdas_outcome_name AS outcome,
    events.agent
   FROM idm_rpt_data.idmrpt_events_v2 events
  WHERE (events.agent::text ~~ (('%'::text || 'Modular Authentication Services'::text) || '%'::text) OR events.agent::text ~~ (('%'::text || 'NetIQ eDirectory'::text) || '%'::text) OR events.agent::text ~~ (('%'::text || 'NetIQ Self Service Password Reset'::text) || '%'::text)) AND events.xdas_taxonomy_name::text = 'XDAS_AE_SET_CRED_ACCOUNT'::text AND (events.xdas_outcome_name::text = 'XDAS_OUT_SUCCESS'::text OR events.xdas_outcome_name::text = 'XDAS_OUT_FAILURE'::text) AND events.event_name::text ~~ (('%'::text || 'PASSWORD'::text) || '%'::text)
  ORDER BY events.event_datetime;

ALTER TABLE idm_rpt_data.idmrpt_password_summary_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_password_summary_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_password_summary_v TO idmrptuser;




-- User-Password-Changes-within-the-Identity-Vault_4.8.6.0-pg-idmrpt_user_events_v2.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_user_events_v2 AS 
SELECT event.id AS event_seq_no, 
  event.evt AS event_name, 
  event.rv40 AS event_id, 
  event.dt AS event_datetime, 
  idm_rpt_data.get_formatted_user_dn(event.rv35, event.sun) AS event_source_user, 
  idm_rpt_data.get_formatted_user_dn(event.rv45, event.dun) AS event_destination_user, 
  id.full_name AS event_target_user_name, 
  event.msg AS message, 
  event.fn, 
  event.rv31, 
  idv_driver.idv_name, 
  idv_driver.idv_host, 
  idv_driver.idv_id, 
  idv_driver.rpt_drv_id, 
  id.identity_id, 
  id.first_name, 
  id.last_name, 
  id.middle_initial, 
  id.full_name, 
  id.job_title, 
  id.department, 
  id.location, 
  id.email_address, 
  id.identity_desc, 
  event.rv43, 
  event.xdasprov AS xdas_provider, 
  event.xdasreg AS xdas_registry, 
  event.xdasclass AS xdas_class, 
  event.xdasid AS xdas_identifier, 
  event.xdastaxname AS xdas_taxonomy_name,
  event.xdasoutcome AS xdas_outcome,
  event.xdasoutcomename AS xdas_outcome_name,
  event.xdasdetail AS xdas_detail
  FROM
    idm_rpt_data.idmrpt_identity_cs_v id
  INNER JOIN
    idm_rpt_data.idmrpt_idv_acct_all_v id_acct
  ON
    id.identity_id = id_acct.identity_id
  INNER JOIN
    idm_rpt_data.idmrpt_idv_v idv
  ON
    id_acct.idv_id = idv.idv_id
  LEFT OUTER JOIN
    idm_rpt_data.idmrpt_rpt_driver_v idv_driver
  ON
    id_acct.rpt_drv_id = idv_driver.rpt_drv_id
  INNER JOIN
    public.sentinel_events event ON 
CASE
WHEN event.dun IS NOT NULL THEN id_acct.idv_acct_user::text = lower(event.dun::text)
ELSE 
CASE
WHEN event.dun IS NULL THEN id_acct.idv_acct_user::text = lower(event.iuid::text)
ELSE 
CASE
    WHEN event.dun::text ~~ '%cn=%o=%'::text THEN lower(event.dun::text) = lower(id_acct.idv_acct_dn::text) 
ELSE 
	CASE
        WHEN event.dun::text = 'loginDisabled'::text OR event.dun::text = 'Locked By Intruder'::text OR event.dun::text ~~ 'Login Intruder%'::text THEN id_acct.idv_acct_user::text = lower(event.sun::text)
        ELSE id_acct.idv_acct_user::text = lower(event.dun::text)
    END
END
END
END AND 
CASE
    WHEN event.rv45 IS NULL THEN id_acct.idv_acct_domain::text = lower(event.rv35::text)
    ELSE 
    CASE
        WHEN event.rv45::text ~~ '%cn=%o=%'::text THEN id_acct.idv_acct_dn::text = lower(event.rv45::text)
        ELSE 
		CASE 
		    WHEN event.rv45 IS NOT NULL THEN id_acct.idv_acct_domain::text = lower(event.rv45::text)
			ELSE id_acct.idv_acct_domain::text = lower(event.rv45::text)
		END
    END
END;
ALTER TABLE idm_rpt_data.idmrpt_user_events_v2 OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_user_events_v2 TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_user_events_v2 TO idmrptuser;



-- User-Status-Changes-within-the-Identity-Vault_4.8.6.0-pg-idmrpt_user_events_v2.sql

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_user_events_v2 AS 
SELECT event.id AS event_seq_no, 
  event.evt AS event_name, 
  event.rv40 AS event_id, 
  event.dt AS event_datetime, 
  idm_rpt_data.get_formatted_user_dn(event.rv35, event.sun) AS event_source_user, 
  idm_rpt_data.get_formatted_user_dn(event.rv45, event.dun) AS event_destination_user, 
  id.full_name AS event_target_user_name, 
  event.msg AS message, 
  event.fn, 
  event.rv31, 
  idv_driver.idv_name, 
  idv_driver.idv_host, 
  idv_driver.idv_id, 
  idv_driver.rpt_drv_id, 
  id.identity_id, 
  id.first_name, 
  id.last_name, 
  id.middle_initial, 
  id.full_name, 
  id.job_title, 
  id.department, 
  id.location, 
  id.email_address, 
  id.identity_desc, 
  event.rv43, 
  event.xdasprov AS xdas_provider, 
  event.xdasreg AS xdas_registry, 
  event.xdasclass AS xdas_class, 
  event.xdasid AS xdas_identifier, 
  event.xdastaxname AS xdas_taxonomy_name,
  event.xdasoutcome AS xdas_outcome,
  event.xdasoutcomename AS xdas_outcome_name,
  event.xdasdetail AS xdas_detail
  FROM
    idm_rpt_data.idmrpt_identity_cs_v id
  INNER JOIN
    idm_rpt_data.idmrpt_idv_acct_all_v id_acct
  ON
    id.identity_id = id_acct.identity_id
  INNER JOIN
    idm_rpt_data.idmrpt_idv_v idv
  ON
    id_acct.idv_id = idv.idv_id
  LEFT OUTER JOIN
    idm_rpt_data.idmrpt_rpt_driver_v idv_driver
  ON
    id_acct.rpt_drv_id = idv_driver.rpt_drv_id
  INNER JOIN
    public.sentinel_events event ON 
CASE
WHEN event.dun IS NOT NULL THEN id_acct.idv_acct_user::text = lower(event.dun::text)
ELSE 
CASE
WHEN event.dun IS NULL THEN id_acct.idv_acct_user::text = lower(event.iuid::text)
ELSE 
CASE
    WHEN event.dun::text ~~ '%cn=%o=%'::text THEN lower(event.dun::text) = lower(id_acct.idv_acct_dn::text) 
ELSE 
	CASE
        WHEN event.dun::text = 'loginDisabled'::text OR event.dun::text = 'Locked By Intruder'::text OR event.dun::text ~~ 'Login Intruder%'::text THEN id_acct.idv_acct_user::text = lower(event.sun::text)
        ELSE id_acct.idv_acct_user::text = lower(event.dun::text)
    END
END
END
END AND 
CASE
    WHEN event.rv45 IS NULL THEN id_acct.idv_acct_domain::text = lower(event.rv35::text)
    ELSE 
    CASE
        WHEN event.rv45::text ~~ '%cn=%o=%'::text THEN id_acct.idv_acct_dn::text = lower(event.rv45::text)
        ELSE 
		CASE 
		    WHEN event.rv45 IS NOT NULL THEN id_acct.idv_acct_domain::text = lower(event.rv45::text)
			ELSE id_acct.idv_acct_domain::text = lower(event.rv45::text)
		END
    END
END;
ALTER TABLE idm_rpt_data.idmrpt_user_events_v2 OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_user_events_v2 TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_user_events_v2 TO idmrptuser;



-- User-Status-Changes-within-the-Identity-Vault_4.8.6.0-pg-idmrpt_user_status_v.sql

-- View: idm_rpt_data.idmrpt_user_status_v

-- DROP VIEW idm_rpt_data.idmrpt_user_status_v;

CREATE OR REPLACE VIEW idm_rpt_data.idmrpt_user_status_v AS 

SELECT DISTINCT event_data.identity_id,
event_data.first_name,
    event_data.middle_initial,
    event_data.last_name,
    event_data.event_datetime,
        CASE
            WHEN event_data.rv43::text ~~ '<%'::text THEN ''::text
            ELSE ' : '::text || event_data.rv43::text
        END AS rv43,
        CASE
            WHEN event_data.message::text ~~ '%0029006A%'::text THEN event_data.message::text
            ELSE split_part(event_data.message::text, ':'::text, 1)
        END AS message,
    event_data.xdas_taxonomy_name,
    event_data.event_name AS event,
        CASE
            WHEN event_data.event_id::text = '00031411'::text THEN event_data.event_datetime
            ELSE date_trunc('minute'::text, event_data.event_datetime)
        END AS time_stamp,
    event_data.event_id,
        CASE
            WHEN btrim(event_data.idv_host::text) = btrim(event_data.idv_name::text) THEN event_data.idv_name::text
            ELSE ((event_data.idv_name::text || ' ('::text) || event_data.idv_host::text) || ')'::text
        END AS idv_name
   FROM idm_rpt_data.idmrpt_user_events_v2 event_data
WHERE
(
(event_id='0003000C' and (xdas_provider=0 and xdas_registry=0 and xdas_class=3 and xdas_identifier=3) )--Move Object
--provider=0 and registry=0 and class=3 and identifier=3 and xdas_taxonomy_name='XDAS_AE_MODIFY_DATA_ITEM_ATT'

--OR
--(event_id='0003000A' and xdas_taxonomy_id='101603' and event_target_user_name is not null)--Modify Object
OR
(event_id='0003000B' and (xdas_provider=0 and xdas_registry=0 and xdas_class=3 and xdas_identifier=3))-- Rename user name in Imanager
--iManager event_id='0003000B' and provider=0 and registry=0 and class=3 and identifier=3 and xdas_taxonomy_name='XDAS_AE_MODIFY_DATA_ITEM_ATT'

OR
(event_id='00031400' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=1))-- Subscriber Delete Entry
OR
(event_id='00030009' and xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=1 and xdas_taxonomy_name='XDAS_AE_DELETE_ACCOUNT')

OR
(event_id='0003002B' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=5))-- Subscriber Remove Value
--provider=0 and registry=0 and class=0 and identifier=5 and xdas_taxonomy_name='XDAS_AE_MODIFY_ACCOUNT'

OR
(event_id='00030016' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=5) and rv43 = 'true')-- login disabled
--iManager event_id='0003002A' and provider=0 and registry=0 and class=0 and identifier=5 and xdas_taxonomy_name='XDAS_AE_MODIFY_ACCOUNT' and rv43='true'

OR
(event_id='00030015' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=5) and rv43 = 'false')-- login enabled
--iManager event_id='0003002A' and provider=0 and registry=0 and class=0 and identifier=5 and xdas_taxonomy_name='XDAS_AE_MODIFY_ACCOUNT' and rv43='false'

OR
(event_id='000B0224' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=8))
--provider=0 and registry=0 and class=0 and identifier=8 and xdas_taxonomy_name='XDAS_AE_REVOKE_ACCOUNT_ACCESS'

OR
(event_id='000B0225' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=8))
--provider=0 and registry=0 and class=0 and identifier=8 and xdas_taxonomy_name='XDAS_AE_REVOKE_ACCOUNT_ACCESS'

OR
(event_id='00031411' AND xdas_provider = 0 AND xdas_registry = 0 AND xdas_class = 0 AND xdas_identifier = 6)--Change password from left panel
--iManager event_id='0003000B' and provider=0 and registry=0 and class=0 and identifier=6 and xdas_taxonomy_name='XDAS_AE_SET_CRED_ACCOUNT'

OR
(event_id='00031660' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=5))--Modify user info
--iManager
OR
(event_id='0003000A' and xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=5 and xdas_taxonomy_name='XDAS_AE_MODIFY_ACCOUNT' and event_source_user IS NOT NULL)

OR
(event_id='00031674' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=5))--Modify user info
--iManager event_id='0003000A' and provider=0 and registry=0 and class=0 and identifier=5 and xdas_taxonomy_name='XDAS_AE_MODIFY_ACCOUNT' and event_source_user IS NOT NULL

OR
(event_id='00031401' and (xdas_provider=0 and xdas_registry=0 and xdas_class=4 and xdas_identifier=3))--Rename user login name
--provider=0 and registry=0 and class=4 and identifier=3 and xdas_taxonomy_name='XDAS_AE_QUERY_SERVICE_CONFIG'

OR
(event_id='0003000C' and (xdas_provider=0 and xdas_registry=0 and xdas_class=4 and xdas_identifier=3))--Move object to different domain
--provider=0 and registry=0 and class=4 and identifier=3 and xdas_taxonomy_name='XDAS_AE_QUERY_SERVICE_CONFIG'

OR
(event_id is null  AND xdas_provider = 0 AND xdas_registry = 0 AND xdas_class = 0 AND xdas_identifier = 6)--Password change from home icon
--provider=0 and registry=0 and class=0 and identifier=6 and xdas_taxonomy_name='XDAS_AE_SET_CRED_ACCOUNT'

OR
(event_id='00031440' and (xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=0))--Create user from both idm and iManager
--idm creation 
OR
(event_id='00030008' and xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=0 and xdas_taxonomy_name='XDAS_AE_CREATE_ACCOUNT')

--(event_id='00031440' and xdas_taxonomy_id='101201')--Create user,removed b/c it is only picking the iManager
OR
(event_id='0029006A'  AND xdas_provider = 0 AND xdas_registry = 0 AND xdas_class = 0 AND xdas_identifier = 6)-- password change through iManager Admin Set Password
--provider=0 and registry=0 and class=0 and identifier=6 and xdas_taxonomy_name='XDAS_AE_SET_CRED_ACCOUNT'
OR
(event_id='00030012' AND xdas_provider=0 and xdas_registry=0 and xdas_class=0 and xdas_identifier=6 and xdas_taxonomy_name='XDAS_AE_SET_CRED_ACCOUNT')
OR
(event_id='00030001' AND xdas_provider=0 and xdas_registry=0 and xdas_class=1 and xdas_identifier=4 and xdas_taxonomy_name='XDAS_AE_QUERY_TRUST')
)
OR
event_id = 'CEF0B0004' -- Move object
OR
event_id = 'CEF0B0003' -- Rename object
OR
event_id='CEF0B0337' -- Delete member
OR
event_id='CEF0B0356' -- Login disabled
OR
event_id='CEF0B0355' -- Login enabled
OR
event_id = 'CEF0B035F' -- Account unlock
OR
event_id = 'CEF0B0354' -- ACL changed
OR
event_id = 'CEF0290064' and rv43 IS NOT NULL -- Change Password
OR
event_id = 'CEF029006A' and rv43 IS NOT NULL -- Change Password Thru iManager
OR
event_id = 'CEF0290071' and rv43 IS NOT NULL -- Change Password thru SSPR
   ORDER BY event_data.event_datetime;

ALTER TABLE idm_rpt_data.idmrpt_user_status_v
  OWNER TO idm_rpt_data;
GRANT ALL ON TABLE idm_rpt_data.idmrpt_user_status_v TO idm_rpt_data;
GRANT SELECT ON TABLE idm_rpt_data.idmrpt_user_status_v TO idmrptuser;


