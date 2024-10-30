-- Input: database name
CREATE OR REPLACE FUNCTION idm_rpt_data.get_formatted_user_dn(
	user_path character varying,
	user_name character varying)
RETURNS character varying AS
$BODY$
DECLARE
	new_path    varchar;  
	new_path_2    varchar;
	l_user_path   varchar;
	l_new_delimiter   varchar(1) := '.';
	l_old_delimiter   varchar(3) := E'\\B'; 
	token2 RECORD;
BEGIN

  if user_path is not null 
	   then      
	   
	     l_user_path := user_path;       
	     l_user_path := substring ( l_user_path from 2 );                            
	     for token2 in ( SELECT FOO FROM regexp_split_to_table( l_user_path , l_old_delimiter ) AS FOO  )
	     loop
	        if token2.FOO is not null
	      then                      
	         new_path   := l_new_delimiter||token2.FOO; 
	       end if;    
	      if new_path_2 is not null
	      then                                  
	          new_path   := new_path || new_path_2; 
	       end if; 
	          new_path_2 := new_path; 
	          
	     end loop;  
	     
	     if  new_path is not null 
	     then
	         new_path := user_name||new_path;
	     else 
	           new_path := user_name;        
	     end if; 
	     
	     
	    return rtrim( new_path); 
	       
	   else 
	       return null ; 
	   end if; 
	   
	      
	   END ;
$BODY$
LANGUAGE plpgsql
/* Put semicolon on its own line so that this will be treated as a single statement by the maven SQL plutin */
;
