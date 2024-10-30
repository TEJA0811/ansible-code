package com.netiq.idm.install.rbpm.patch.ua;

import java.io.File;
import java.io.PrintWriter;
import java.io.StringWriter;

import com.netiq.idm.install.rbpm.patch.conf.IsmConfiguration;

public class GetIDMProvPortalContext {
    
    private static final int SUCCESS = 0;
    private static final int ERROR = 1;
    
    static String tomcatConfPath = null;

    static IsmConfiguration ismConfig = null;
    
    public static void main(String[] args) {
        
        if(args.length < 1){
            System.out.println("Usage: com.netiq.idm.install.rbpm.patch.ua.GetIDMProvPortalContext "
                                    + "<Tomcat Home Directory>");
            System.exit(ERROR);
        }
        
        tomcatConfPath =            args[0] + File.separator + "conf";
        
        try{
            
            IsmConfiguration ismConfig = new  IsmConfiguration(tomcatConfPath + File.separator + "ism-configuration.properties");
             
            String contextName = ismConfig.getUserAppPortalContext();
            
            System.out.println(contextName);
            
            
        }catch(Exception e){
            
            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            e.printStackTrace(pw);
            System.out.println(sw.toString());
            
            System.exit(ERROR);
        }
        
        System.exit(SUCCESS);

    }

}
