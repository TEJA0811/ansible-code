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

import java.util.List;

import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;

import org.apache.commons.configuration.ConfigurationException;
import org.apache.commons.configuration.HierarchicalConfiguration;
import org.apache.commons.configuration.XMLConfiguration;
import org.apache.commons.configuration.tree.ConfigurationNode;

//import com.netiq.idm.install.rbpm.patch.actions.LogInstallInfoAction;
import com.netiq.idm.install.rbpm.patch.util.XMLReader;

public class IdmUserAppLogging {
    
    private String m_XMLFilePath = null;
    XMLConfiguration config = null;
    
    public IdmUserAppLogging(String xmlFilePath){
        
        m_XMLFilePath = xmlFilePath;
        
        try {
                config = new XMLConfiguration(xmlFilePath){

                    private static final long serialVersionUID = 1L;

                    @Override
                    protected Transformer createTransformer () throws TransformerException {
                        Transformer transformer = super.createTransformer ();
                        transformer.setOutputProperty (OutputKeys. INDENT, "yes");
                        transformer.setOutputProperty ("{http://xml.apache.org/xslt}indent-amount", "4");
                        return transformer;
                    }
                    
                
                };
        } catch (Exception e) {
            
            System.out.println("IdmUserAppLogging Exception: "+ e.getMessage());
        }
        
    }
    
    
    public boolean isNovellAuditingEnabled(){
        
        boolean enabled = false;
        
        String xPathExpr = "/logging/loggers/logger[@name=\"com.novell\"]/appender-ref[@ref=\"NAUDIT\"]";
        
        boolean auditNovell = XMLReader.nodeExists(m_XMLFilePath, xPathExpr);
        
        xPathExpr = "/logging/loggers/logger[@name=\"com.sssw\"]/appender-ref[@ref=\"NAUDIT\"]";
        
        boolean auditSSSW = XMLReader.nodeExists(m_XMLFilePath, xPathExpr);
        
        xPathExpr = "/logging/loggers/logger[@name=\"com.netiq\"]/appender-ref[@ref=\"NAUDIT\"]";
        boolean auditNetiq = XMLReader.nodeExists(m_XMLFilePath, xPathExpr);
        
        if(auditNovell && auditSSSW && auditNetiq){
            enabled = true;
        }
        
        return enabled;
    }
    
    public void addAppenderParameter(String appenderName, ConfigurationNode paramNode) throws ConfigurationException{
        System.out.println("Adding a new parameter to the appender " + appenderName);
        System.out.println("<param name=\"" + paramNode.getAttributes("name").get(0).getValue().toString() + "\"" +
                                          " value=\"" + paramNode.getAttributes("value").get(0).getValue().toString() + "\"" + " />");
        
        ConfigurationNode root = config.getRootNode();
        
        List<ConfigurationNode> appenders = root.getChildren("appenders").get(0).getChildren();
        
        for(ConfigurationNode node:appenders){
            
            String nodeName = node.getAttributes("name").get(0).getValue().toString();
            
            ConfigurationNode param = new HierarchicalConfiguration.Node("param"); 
            ConfigurationNode nameAttribute = new HierarchicalConfiguration.Node("name",
                                                               paramNode.getAttributes("name").get(0).getValue());
            param.addAttribute(nameAttribute); 
            
            ConfigurationNode valueAttribute = new HierarchicalConfiguration.Node("value",
                                                               paramNode.getAttributes("value").get(0).getValue());
            param.addAttribute(valueAttribute);
            
            if(nodeName.equals(appenderName)){
                
                //Check if the same parameter already exists for the appender
                boolean paramAlreadyExists = false;
                List<ConfigurationNode> paramList = node.getChildren("param");
                for(ConfigurationNode child:paramList){
                    
                    if(child.getAttributes("name").get(0).getValue().toString().equals(param.getAttributes("name").get(0).getValue().toString())){
                        paramAlreadyExists = true; 
                    }
                }
                
                if(!paramAlreadyExists){
                    
                    node.addChild(param); 
                }else{
                    System.out.println("The parameter already exists");  
                }
                                          
            }
        }
        
        config.save();    
    }
    
    public void deleteAppenderParameter(String appenderName, ConfigurationNode paramNode) throws ConfigurationException{
        System.out.println("Deleting a parameter of the appender " + appenderName);
        System.out.println("<param name=\"" + paramNode.getAttributes("name").get(0).getValue().toString() + "\"" +
                " value=\"" + paramNode.getAttributes("value").get(0).getValue().toString() + "\"" + " />");
        
        String paramName = paramNode.getAttributes("name").get(0).getValue().toString();
        System.out.println("logging/appenders/appender[@name=\""+ appenderName + "\"]/param[@name=\""+ paramName + "\"]");
        config.clearProperty("logging/appenders/appender[@name=\""+ appenderName + "\"]/param[@name=\""+ paramName + "\"]");
        
        config.save();

    }

}
