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
package com.netiq.idm.install.rbpm.patch.conf;

import java.io.File;
import java.io.IOException;

import org.apache.commons.configuration.ConfigurationException;
import org.apache.commons.configuration.PropertiesConfiguration;

public class IsmConfiguration {
    
    private PropertiesConfiguration m_properties = null;
    
    public IsmConfiguration(String configFilePath) throws IOException{
        
        File configFile = new File(configFilePath);
        
        if(configFile.exists()){
            loadProperties(configFilePath);  
        }
          
    }
    
    public boolean exists(){
        return m_properties != null;
    }
    
    private void loadProperties(String configFilePath) throws IOException{
        
        try
        {
            m_properties = new PropertiesConfiguration();
            m_properties.setDelimiterParsingDisabled(true);
            m_properties.load(configFilePath); 
            m_properties.setFileName(configFilePath);
        }
        catch(ConfigurationException cex)
        {
            
        }
        
    }
    
    public String getProperty(String key){
         
        return m_properties.getString(key); 
        
    }
    
    public String getOSPServletProtocol(){
   
        String servletProtocol = null;
              
        String ospServletUrl = m_properties.getString("com.netiq.client.authserver.url.authorize"); /* http(s)://hostname:port/osp/a/idm/auth/oauth2/grant*/
        if(ospServletUrl != null){
            String[] split = ospServletUrl.split(":");
            servletProtocol = split[0].trim();
            
        }else{
            
            ospServletUrl = m_properties.getString("com.netiq.idm.osp.url.host"); /* http(s)://HostName:port */
            if(ospServletUrl != null){
                String[] split = ospServletUrl.split(":");
                servletProtocol = split[0].trim();
            }
            
        }
        
        return servletProtocol;
        
    }
    
    public String getOSPServletHost(){
        
        String servletHost = null;
        
        String ospServletUrl = m_properties.getString("com.netiq.client.authserver.url.authorize"); /* http(s)://hostname:port/osp/a/idm/auth/oauth2/grant*/
        if(ospServletUrl != null){
            String[] split = ospServletUrl.split(":");
            servletHost = split[1].replace("/", "").trim();
        }else{
            
            ospServletUrl = m_properties.getString("com.netiq.idm.osp.url.host"); /* http(s)://HostName:port */
            if(ospServletUrl != null){
                String[] split = ospServletUrl.split(":");
                servletHost = split[1].replace("/", "").trim();
            }
            
        }

        return servletHost;
        
    }
    
    public String getOSPServletPort(){
        
        String servletPort = null;
        
        String ospServletUrl = m_properties.getString("com.netiq.client.authserver.url.authorize"); /* http(s)://hostname:port/osp/a/idm/auth/oauth2/grant*/
        if(ospServletUrl != null){
            String[] split = ospServletUrl.split(":");
            servletPort = split[2].split("/")[0].replace("/", "").trim();
        }else{
            
            ospServletUrl = m_properties.getString("com.netiq.idm.osp.url.host"); /* http(s)://HostName:port */
            if(ospServletUrl != null){
                String[] split = ospServletUrl.split(":");
                servletPort = split[2].trim();
            }
            
        }
        
        return servletPort;  
    }
    
    public String getOSPUseSSL(){
        return m_properties.getString("com.netiq.idm.osp.ldap.use-ssl");
    }
        
    public String getOSPSSLKeyStoreFile(){
        return m_properties.getString("com.netiq.idm.osp.ssl-keystore.file");
    }
    
    public String getOSPLdapHost(){
        return m_properties.getString("com.netiq.idm.osp.ldap.host");
    }
    
    public String getOSPLdapPort(){
        return m_properties.getString("com.netiq.idm.osp.ldap.port");
    }
    
    public String getOSPLdapAdminDN(){
        
        String ldapAdminDN = null;
        
        ldapAdminDN = m_properties.getString("com.novell.idm.ldap.admin.user");
        
        if(ldapAdminDN == null){
            
            ldapAdminDN = m_properties.getString("com.netiq.idm.osp.ldap.admin-dn");
              
        }
        
        return ldapAdminDN;
    }
    
    
    public String getOSPUserContrainerDN(){
        return m_properties.getString("com.netiq.idm.osp.as.users-container-dn");
    }
    
    public String getOSPAdminContrainerDN(){
        return m_properties.getString("com.netiq.idm.osp.as.admins-container-dn");
    } 
    
    public String getUserAppPortalContext(){
        return m_properties.getString("portal.context");
    }
    
    
    public String getUserAppMasterKey(){
        return m_properties.getString("com.novell.idm.masterkey");
    }
    
    public String getUserAppServletProtocol(){
        
        String servletProtocol = null;
        String ospUrlHost = m_properties.getString("com.netiq.rbpm.redirect.url"); /* http(s)://HostName:port/IDMProv/oauth */
        if(ospUrlHost != null){
            String[] split = ospUrlHost.split(":");
            servletProtocol = split[0].trim();
        }
        
        return servletProtocol;
        
    }
    
    public String getUserAppServletHost(){
        
        String servletHost = null;
        String ospUrlHost = m_properties.getString("com.netiq.rbpm.redirect.url"); /* http(s)://HostName:port/IDMProv/oauth */
        if(ospUrlHost != null){
            String[] split = ospUrlHost.split(":");
            servletHost = split[1].replace("//", "").trim();
        }
        
        return servletHost;
        
    }
    
    public String getUserAppServletPort(){
        
        String servletPort = null;
        String ospUrlHost = m_properties.getString("com.netiq.rbpm.redirect.url"); /* http(s)://HostName:port/IDMProv/oauth */
        if(ospUrlHost != null){
            String[] split = ospUrlHost.split(":");
            servletPort = split[2].split("/")[0].trim();
            
        }
        
        return servletPort;  
    }
    
    public void setProperty(String property, String value) throws ConfigurationException{
            System.out.println("Setting " + property + " to " + value);
            m_properties.setProperty(property, value);
            m_properties.save();
  
    }
    
    public void deleteProperty(String property) throws ConfigurationException{
            System.out.println("Deleting property " + property);
            m_properties.clearProperty(property);
            m_properties.save();

    }
}
