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
package com.netiq.idm.install.rbpm.patch.osp;

import java.io.File;
import java.util.List;

import org.apache.commons.configuration.XMLConfiguration;
import org.apache.commons.configuration.tree.ConfigurationNode;
import org.apache.commons.io.FileUtils;

import com.netiq.idm.install.rbpm.patch.conf.IdmUserAppLogging;
import com.netiq.idm.install.rbpm.patch.conf.IsmConfiguration;


public class ApplyConfigChanges {
    
    private static final int SUCCESS = 0;
    private static final int ERROR = 1;

    static String configChangesTemplatePath = null;
    static XMLConfiguration configChangesTemplate = null;
    
    static File configBackupDir = null;
    
    static String tomcatConfPath = null;
    
    static IsmConfiguration ismConfig = null;
    static IdmUserAppLogging idmUserAppLoggingXML = null;
    
    
    public static void main(String[] args){
        
        if(args.length < 3){
            System.out.println("Usage: com.netiq.idm.install.rbpm.patch.osp.ApplyConfigChanges "
                                    + "<Config Changes Template Path> "
                                    + "<Tomcat Home Directory> "
                                    + "<Config Backup Folder>");
            System.exit(ERROR);
        }
        
        System.out.println("Applying configuration changes...");
        
        configChangesTemplatePath = args[0];   
        tomcatConfPath =            args[1] + File.separator + "conf";              
        
        configBackupDir = new File(args[2] + File.separator + "conf");
        
        try {
            
            configChangesTemplate = new XMLConfiguration(configChangesTemplatePath);
            
           
            if(configChangesTemplate.getRootNode().getChildren("ism-configuration").size() > 0){
                updateIsmConfiguration(); 
            }
                       
      
            
        } catch (Exception e) {
            
            System.err.println("There was a problem committing configuration update \n" + e.getMessage() + "\n");
            System.exit(ERROR);
            
        }
        
        System.exit(SUCCESS);
    }
    
    
    
    public static void updateIsmConfiguration() throws Exception{
        
        try {
            
            String configFilePath = tomcatConfPath + File.separator + "ism-configuration.properties";
            
            //First take a backup of config file
            System.out.println("Backing up " + "ism-configuration.properties" + " to " + configBackupDir);
            FileUtils.copyFileToDirectory(new File(configFilePath), configBackupDir);
            
            System.out.println("Updating ism-configuration.properties");
            
            ismConfig = new  IsmConfiguration(configFilePath);
            
            ConfigurationNode root = configChangesTemplate.getRootNode();
            
            ConfigurationNode ismConfigNode = root.getChildren("ism-configuration").get(0);
            
            List<ConfigurationNode> nodes = ismConfigNode.getChildren();
            
            for(ConfigurationNode node:nodes){
                
                if(node.getName().equals("set-property")){
                   ismConfig.setProperty((String)node.getAttribute(0).getValue(), (String)node.getValue()) ; 
                   
                }else if(node.getName().equals("delete-property")){
                   ismConfig.deleteProperty((String)node.getAttribute(0).getValue()) ;
                   
                }else{
                    System.err.println("UpdateIsmConfiguration: Invalid configuration " + node.getName());
                }
            }
            
        }catch(Exception e){
            
            throw new Exception("Could not update ism-configuration.properties\n" + e.getMessage());

        }
        
    }
    
}
