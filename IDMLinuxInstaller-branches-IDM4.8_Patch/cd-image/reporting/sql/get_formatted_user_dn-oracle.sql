create or replace Function idm_rpt_data.get_formatted_user_dn
                                                (
                                                    user_path IN varchar2
                                                  , user_name IN varchar2
                                                )
    RETURN varchar2
IS
    new_path        varchar2(32767);
    new_path_2      varchar2(32767);
    l_user_path     varchar2(32767);
    l_new_delimiter varchar2(1) := '.';
BEGIN
    if user_path is not null then
        FOR token2 IN
        (
               select
                      item
               from
                      xmltable('ora:tokenize($v, "\\")' passing user_path as "v" columns item varchar2(999) path '.' )
        )
        LOOP
            if token2.item is not null then
                dbms_output.put_line( token2.item );
                new_path := l_new_delimiter
                ||token2.item;
            end if;
            if new_path_2 is not null then
                new_path := new_path
                || new_path_2;
            end if;
            new_path_2 := new_path;
        END LOOP;
        if new_path is not null then
            new_path := user_name
            ||new_path;
        else
            new_path := user_name;
        end if;
        return trim(new_path);
    else
        return null;
    end if;
END;
