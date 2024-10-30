/*
 * ========================================================================
 *
 * Copyright (c) 2017 Unpublished Work of NetIQ Corporation. All Rights Reserved.
 *
 * THIS WORK IS AN UNPUBLISHED WORK AND CONTAINS CONFIDENTIAL,
 * PROPRIETARY AND TRADE SECRET INFORMATION OF NETIQ. ACCESS TO
 * THIS WORK IS RESTRICTED TO (I) NETIQ EMPLOYEES WHO HAVE A NEED
 * TO KNOW HOW TO PERFORM TASKS WITHIN THE SCOPE OF THEIR ASSIGNMENTS AND
 * (II) ENTITIES OTHER THAN NETIQ WHO HAVE ENTERED INTO
 * APPROPRIATE LICENSE AGREEMENTS. NO PART OF THIS WORK MAY BE USED,
 * PRACTICED, PERFORMED, COPIED, DISTRIBUTED, REVISED, MODIFIED,
 * TRANSLATED, ABRIDGED, CONDENSED, EXPANDED, COLLECTED, COMPILED,
 * LINKED, RECAST, TRANSFORMED OR ADAPTED WITHOUT THE PRIOR WRITTEN
 * CONSENT OF NETIQ. ANY USE OR EXPLOITATION OF THIS WORK WITHOUT
 * AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND CIVIL
 * LIABILITY.
 *
 * ========================================================================
 */
package com.netiq.idm.install.rbpm.patch.ua;

import java.io.File;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;

import com.netiq.idm.install.rbpm.patch.conf.IsmConfiguration;
import com.netiq.idm.install.rbpm.patch.util.ZipUtility;


public class RestoreIDMProvPortalContext{
    
    private static final int SUCCESS = 0;
    private static final int ERROR = 1;

    private static String contextName = "IDMProv";
        
   
    public static void main(String[] args){
       
        if(args.length < 2){
            System.out.println("Usage: com.netiq.idm.install.rbpm.patch.ua.RestoreIDMProvPortalContext "
                                    + "<Tomcat Home Directory> "
                                    + "<Installer Temp Directory>");
            System.exit(ERROR);
        }
        
        System.out.println("Restoring Application Context...");
        
        
        String tomcatHome = args[0];
        String installerTempDir = args[1];
       
                
        try{
            
           IsmConfiguration ismConfig = new  IsmConfiguration(tomcatHome + File.separator + "conf" + File.separator + "ism-configuration.properties");
            
           contextName = ismConfig.getUserAppPortalContext();
           
           File idmProvWAR = new File(tomcatHome + File.separator + "webapps" + File.separator + "IDMProv.war"); 
           File newWAR = new File(idmProvWAR.getParentFile() + File.separator +  contextName + ".war");
           
           //First rename the war to its original context name
           System.out.println("Renaming " + idmProvWAR + " to " + newWAR);
           idmProvWAR.renameTo(newWAR);
           
           //Now explode the war to temp location
           File extractToFolder = new File(installerTempDir + File.separator + FilenameUtils.removeExtension(newWAR.getName()));
           System.out.println("Exploding " + newWAR + " to " + extractToFolder);
           ZipUtility.unzipAll(newWAR, extractToFolder);
           
           //Update web.xml with the original context name
           UpdateWebXMLWithNewContext(extractToFolder.getAbsolutePath());
           
           System.out.println("Zipping " + extractToFolder.getAbsolutePath() + " to " + contextName + ".war");
           ZipUtility.createZip(extractToFolder.getParentFile() + File.separator + contextName + ".war", extractToFolder.getAbsolutePath());
           
           
           System.out.println("Copying " + extractToFolder.getParentFile() + File.separator + contextName + ".war to " +
                                                                                         newWAR.getParentFile().getAbsolutePath());
           FileUtils.copyFileToDirectory(new File(extractToFolder.getParentFile() + File.separator + contextName + ".war"), 
                                                                        idmProvWAR.getParentFile());
           
           System.out.println("Successfully restored Application Context to " + contextName);
           
       }catch(Exception e){
          
           System.err.println("There was a problem restoring Application Context to " + contextName + "\n" + e.getMessage() + "\n" + getWorkaroundNotes());
           
           System.exit(ERROR);
       }
        
        System.exit(SUCCESS);
    }
    
    public static void UpdateWebXMLWithNewContext(String warFolderPath) throws Exception{
        
        Path webXMLPath = Paths.get(warFolderPath + File.separator + "WEB-INF" + File.separator + "web.xml");
        
        try {
            System.out.println("Updating " + webXMLPath.toString());
            Charset charset = StandardCharsets.UTF_8;
            String content = new String(Files.readAllBytes(webXMLPath),charset);
            content = content.replaceAll("<display-name>IDMProv</display-name>", 
                                                              "<display-name>" + contextName + "</display-name>");
            Files.write(webXMLPath, content.getBytes(charset)); 
            
            System.out.println("Replaced <display-name>IDMProv</display-name> with " + "<display-name>" + contextName + "</display-name>");
            
        } catch (Exception e) {
            
            throw new Exception(contextName + ".war: Failed to update web.xml with original context name \n" + e.getMessage());
        }

        
    }
    
    public static String getWorkaroundNotes(){
        
        String workaroundNotes = "\nYou can manually restore the Application Context by using ConfigUpdate tool:\n" +
        "a) Launch the ConfigUpdate tool\n" +
        "b) Go to User Application tab -> Show Advanced Options -> Change RBPM Context Name\n" +
        "c) Set RBPM context name to " + contextName + " and click OK\n" +
        "d) On Linux: Change the permission and ownership of " + contextName + ".war using the following command:\n" +
        "     chmod 777 " + contextName + ".war; chown -R novlua:novlua "+ contextName+".war\n" ;
        
        return workaroundNotes;
    }

}
