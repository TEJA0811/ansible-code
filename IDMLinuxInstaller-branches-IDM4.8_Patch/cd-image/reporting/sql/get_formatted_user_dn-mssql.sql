CREATE FUNCTION [IDM_RPT_DATA].[get_formatted_user_dn] 
(
       -- Add the parameters for the function here
       @user_path nvarchar(max)
   , @user_name nvarchar(200)
)
RETURNS nvarchar(max)
AS
BEGIN
       DECLARE
             @new_path        nvarchar(200),
        @new_path_2      nvarchar(max),
        @l_user_path     nvarchar(max),
        @l_old_delimiter nvarchar(1) = '/',
        @l_new_delimiter nvarchar(1) = '.',
        @MyCursor CURSOR,
        @MyField nvarchar(max);

    if @user_path is not null
    BEGIN
    SET @l_user_path = SUBSTRING(@user_path , 2 , (LEN(@user_path)-1));
    SET @MyCursor = CURSOR FOR
                    SELECT value FROM STRING_SPLIT( @l_user_path , @l_old_delimiter )
    OPEN @MyCursor 
    FETCH NEXT FROM @MyCursor 
    INTO @MyField
        WHILE @@FETCH_STATUS = 0
        BEGIN
            if @MyField is not null
            BEGIN
                SET @new_path = @l_new_delimiter + @MyField;
            END
            if @new_path_2 is not null
            BEGIN
                SET @new_path = @new_path + @new_path_2;
            END
            SET @new_path_2 = @new_path;
          FETCH NEXT FROM @MyCursor 
          INTO @MyField
        END
        CLOSE @MyCursor
        DEALLOCATE @MyCursor
             
        if @new_path is not null
                    BEGIN
                       SET @new_path = @user_name + @new_path;
                    END
        else
                    BEGIN
                           SET @new_path = @user_name;
                    END
    END
       return trim(@new_path);
END;