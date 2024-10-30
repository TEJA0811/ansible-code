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

package com.netiq.idm.install.rbpm.patch.util;

import java.io.File;
import java.util.LinkedHashSet;
import java.util.Set;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;


public final class GlobalZerogRegistry {

    private GlobalZerogRegistry(){
        throw new AssertionError("Default construction has been suppressed for non-instantiability.");
    }
    
    public static Set<String> getProductLocations(String productName){
        
        String registryXMLPath = null;
        
        if(SystemInfo.isWindowsOS()){
            registryXMLPath = SystemInfo.getProgramFilesFolder() + File.separator + "Zero G Registry" + File.separator + ".com.zerog.registry.xml";
            
        }else if(SystemInfo.isLinuxOS()){
            registryXMLPath = "/var" + File.separator + ".com.zerog.registry.xml";
            
        }else{
            return null;
        }
        
        
        Set<String> productLocations = null; 
        
        
        try {

                DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
                Document doc = dBuilder.parse(new File(registryXMLPath));
                XPathFactory xPathfactory = XPathFactory.newInstance();
                XPath xpath = xPathfactory.newXPath();
                XPathExpression expr = xpath.compile("/registry/products/product[@name=\"" + productName + "\"]");
                NodeList nl = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
                
                
                productLocations = new LinkedHashSet<String>();
                for(int i = 0; i < nl.getLength(); i++){
                    
                    Element el = (Element) nl.item(i);
                    String location = el.getAttribute("location");
                    productLocations.add(location);
                    
                }

          } catch (Exception e) {
                e.printStackTrace();
          }
        
        return productLocations;    
    }
    
    public static Set<String> getProductLocations(String productName, String productVersion){
        
        String registryXMLPath = null;
        
        if(SystemInfo.isWindowsOS()){
            registryXMLPath = SystemInfo.getProgramFilesFolder() + File.separator + "Zero G Registry" + File.separator + ".com.zerog.registry.xml";
            
        }else if(SystemInfo.isLinuxOS()){
            registryXMLPath = "/var" + File.separator + ".com.zerog.registry.xml";
            
        }else{
            return null;
        }
        
        
        Set<String> productLocations = null; 
        
        
        try {

                DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
                Document doc = dBuilder.parse(new File(registryXMLPath));
                XPathFactory xPathfactory = XPathFactory.newInstance();
                XPath xpath = xPathfactory.newXPath();
                XPathExpression expr = xpath.compile("/registry/products/product[@name=\"" + productName + "\" and @version=\"" + productVersion + "\"]");
                NodeList nl = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
                
                
                productLocations = new LinkedHashSet<String>();
                for(int i = 0; i < nl.getLength(); i++){
                    
                    Element el = (Element) nl.item(i);
                    String location = el.getAttribute("location");
                    productLocations.add(location);
                    
                }

          } catch (Exception e) {
                e.printStackTrace();
          }
        
        return productLocations;    
    }
    
    public static Set<String> getResourceLocations(String componentName, String resourceName){
        
        String registryXMLPath = null;
        
        if(SystemInfo.isWindowsOS()){
            registryXMLPath = SystemInfo.getProgramFilesFolder() + File.separator + "Zero G Registry" + File.separator + ".com.zerog.registry.xml";
            
        }else if(SystemInfo.isLinuxOS()){
            registryXMLPath = "/var" + File.separator + ".com.zerog.registry.xml";
            
        }else{
            return null;
        }
        
        
        Set<String> resourceLocations = null; 
        
        
        try {

                DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
                Document doc = dBuilder.parse(new File(registryXMLPath));
                XPathFactory xPathfactory = XPathFactory.newInstance();
                XPath xpath = xPathfactory.newXPath();
                XPathExpression expr = xpath.compile("/registry/components/component[@name=\"" + componentName + "\"]/resource[@name=\"" + resourceName + "\"]");
                NodeList nl = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
                
                
                resourceLocations = new LinkedHashSet<String>();
                for(int i = 0; i < nl.getLength(); i++){
                    
                    Element el = (Element) nl.item(i);
                    String location = el.getAttribute("location");
                    resourceLocations.add(location);
                    
                }

          } catch (Exception e) {
                e.printStackTrace();
          }
        
        return resourceLocations;    
    }
}

