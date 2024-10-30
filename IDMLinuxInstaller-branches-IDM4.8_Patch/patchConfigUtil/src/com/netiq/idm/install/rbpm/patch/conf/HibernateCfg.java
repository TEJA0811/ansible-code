package com.netiq.idm.install.rbpm.patch.conf;

import org.apache.commons.configuration.ConfigurationException;
import org.apache.commons.configuration.HierarchicalConfiguration;
import org.apache.commons.configuration.XMLConfiguration;
import org.apache.commons.configuration.tree.ConfigurationNode;

import com.netiq.idm.install.rbpm.patch.util.XMLReader;

public class HibernateCfg {
    
    XMLConfiguration config = null;
    String configurationFilePath = "";
    


    public HibernateCfg(String configFilePath) throws ConfigurationException{
        
            
        configurationFilePath = configFilePath;
            
        config = new XMLConfiguration(configurationFilePath);
                        
        
    }
    
    public void addResorceMapping(String resource) throws ConfigurationException{
        
        ConfigurationNode root = config.getRootNode();
        ConfigurationNode sessionFactorynode = root.getChild(0);
        
        String xPathExpr = "/hibernate-configuration/session-factory/mapping[@resource=\"" + resource + "\"]";
        
        if(!XMLReader.nodeExists(configurationFilePath, xPathExpr)){
            
            ConfigurationNode mappingNode = new HierarchicalConfiguration.Node("mapping");
            sessionFactorynode.addChild(mappingNode);
            
            ConfigurationNode resourceAttr = new HierarchicalConfiguration.Node("resource");
            mappingNode.addAttribute(resourceAttr);
            resourceAttr.setValue(resource);
            
        }
        
        config.save();

    }
    
   public void addClassMapping(String clss) throws ConfigurationException{
        
        ConfigurationNode root = config.getRootNode();
        ConfigurationNode sessionFactorynode = root.getChild(0);
        
        String xPathExpr = "/hibernate-configuration/session-factory/mapping[@class=\"" + clss + "\"]";
        
        if(!XMLReader.nodeExists(configurationFilePath, xPathExpr)){
            
            ConfigurationNode mappingNode = new HierarchicalConfiguration.Node("mapping");
            sessionFactorynode.addChild(mappingNode);
            
            ConfigurationNode classAttr = new HierarchicalConfiguration.Node("class");
            mappingNode.addAttribute(classAttr);
            classAttr.setValue(clss);
            
        }
        
        config.save();
    }

}
