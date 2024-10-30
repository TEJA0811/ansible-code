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

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

public final class XMLReader {
    
    private XMLReader(){
        throw new AssertionError("Default construction has been suppressed for non-instantiability.");
    }
    
    public static String getAttributeValue(String xmlPath, String expression, String attributeName){
        
        String value = null;
        
        try {

                DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
                Document doc = dBuilder.parse(new File(xmlPath));
                XPathFactory xPathfactory = XPathFactory.newInstance();
                XPath xpath = xPathfactory.newXPath();
                XPathExpression expr = xpath.compile(expression);
                NodeList nl = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
                
                
                for(int i = 0; i < nl.getLength(); i++){
                    
                    Element el = (Element) nl.item(i);
                    value = el.getAttribute(attributeName);
                    
                }

          } catch (Exception e) {
                e.printStackTrace();
          }
        
        return value;
        
    }
    
    public static String getTextContent(String xmlPath, String expression){
        
        String value = null;
        
        try {

                DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
                Document doc = dBuilder.parse(new File(xmlPath));
                XPathFactory xPathfactory = XPathFactory.newInstance();
                XPath xpath = xPathfactory.newXPath();
                XPathExpression expr = xpath.compile(expression);
                NodeList nl = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
                
                for(int i = 0; i < nl.getLength(); i++){
                    
                    Element el = (Element) nl.item(i);
                    value = el.getTextContent();
                    
                }

          } catch (Exception e) {
                e.printStackTrace();
          }
        
        return value;
        
    }
    
    public static boolean nodeExists(String xmlPath, String expression){
        
        boolean exists = false;
        
        try {

                DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
                Document doc = dBuilder.parse(new File(xmlPath));
                XPathFactory xPathfactory = XPathFactory.newInstance();
                XPath xpath = xPathfactory.newXPath();
                XPathExpression expr = xpath.compile(expression);
                NodeList nl = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
                
                if(nl.getLength() > 0){
                    exists = true;
                }

          } catch (Exception e) {
              exists = false;  
              e.printStackTrace();
          }
        
        return exists;
        
    }

}
