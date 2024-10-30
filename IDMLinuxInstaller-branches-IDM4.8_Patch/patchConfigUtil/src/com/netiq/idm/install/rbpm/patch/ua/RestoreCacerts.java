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
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.cert.Certificate;
import java.util.ArrayList;
import java.util.Enumeration;


public class RestoreCacerts {


    
    public static void main(String[] args){
        
        String oldCacertsPath = args[0];
        
        String oldCacertsPWD =  args[1];
        
        String newCacertsPath = args[2];
        

        
        try {
            
            System.out.println("Restoring certificates from " + oldCacertsPath + " to " + newCacertsPath );
            
            KeyStore oldKeystore = KeyStore.getInstance(KeyStore.getDefaultType());
            oldKeystore.load(new FileInputStream(oldCacertsPath), oldCacertsPWD.toCharArray());
            
            KeyStore newKeystore = KeyStore.getInstance(KeyStore.getDefaultType());
            newKeystore.load(new FileInputStream(newCacertsPath), "changeit".toCharArray());
            
            ArrayList<String> missingAliases = getMissingCertsAliases(oldKeystore,newKeystore);
            
            for(String alias:missingAliases){
               Certificate cert = oldKeystore.getCertificate(alias);
               newKeystore.setCertificateEntry(alias, cert);  
            }
            
            FileOutputStream out = new FileOutputStream(new File(newCacertsPath));
            newKeystore.store(out, "changeit".toCharArray());
            out.close();
            
        } catch (Exception e) {
            System.err.println("Failed to restore the certificates from " + oldCacertsPath + " to " + newCacertsPath + ": \n" + e.getMessage());
        }
        
    }
    
    public static ArrayList<String> getMissingCertsAliases(KeyStore oldKeystore, KeyStore newKeystore) throws Exception{
        
        ArrayList<String> missingAliases = new ArrayList<String>();
        
        Enumeration<String> oldKeystoreAliases;
        
        try {
            oldKeystoreAliases = oldKeystore.aliases();
            
            while(oldKeystoreAliases.hasMoreElements()){
                String alias = oldKeystoreAliases.nextElement();
                
                if(!newKeystore.containsAlias(alias) && !newKeystore.containsAlias(alias + " [jdk]")){
                    missingAliases.add(alias) ;
                }  
            }
            
        } catch (KeyStoreException e) {
            
            throw new Exception("Error getting missing certificates list\n" + e.getMessage());
        }

        return missingAliases;
        
    }

}
