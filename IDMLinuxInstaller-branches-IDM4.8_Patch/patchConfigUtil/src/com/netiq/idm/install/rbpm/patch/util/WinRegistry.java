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

import java.util.HashMap;
import java.util.Map;

import com.sun.jna.platform.win32.Advapi32Util;
import com.sun.jna.platform.win32.WinReg;
import com.sun.jna.platform.win32.WinReg.HKEY;

public final class WinRegistry {
    
    private static Map<String, HKEY> mapStringToHKEY = new HashMap<String, HKEY>();
    
    private WinRegistry(){
        
        throw new AssertionError("Default construction has been suppressed for non-instantiability.");
        
    }
    
    private static void initMapStringToHKEY(){    
        
        mapStringToHKEY.put("HKLM", WinReg.HKEY_LOCAL_MACHINE);
        mapStringToHKEY.put("HKEY_LOCAL_MACHINE", WinReg.HKEY_LOCAL_MACHINE);
        mapStringToHKEY.put("HKCR", WinReg.HKEY_CLASSES_ROOT);
        mapStringToHKEY.put("HKEY_CLASSES_ROOT", WinReg.HKEY_CLASSES_ROOT);
        mapStringToHKEY.put("HKCC", WinReg.HKEY_CURRENT_CONFIG);
        mapStringToHKEY.put("HKEY_CURRENT_CONFIG", WinReg.HKEY_CURRENT_CONFIG);
        mapStringToHKEY.put("HKCU", WinReg.HKEY_CURRENT_USER);
        mapStringToHKEY.put("HKEY_CURRENT_USER", WinReg.HKEY_CURRENT_USER);
        mapStringToHKEY.put("HKU",  WinReg.HKEY_USERS);
        mapStringToHKEY.put("HKEY_USERS",  WinReg.HKEY_USERS);
    }
    
    private static HKEY getHKEY(String hkeyString){
        
        if(mapStringToHKEY.isEmpty()){
            initMapStringToHKEY();
        }
        
        return mapStringToHKEY.get(hkeyString);
        
    }
    
    private static HashMap<String, String> splitRegistryKeyPath(String path){
        
        HashMap<String, String> map = new HashMap<String, String>();
        
        map.put("hkey", path.substring(0,path.indexOf("\\")));
        map.put("key", path.substring(path.indexOf("\\") + 1, path.length()));
        
        return map;
        
    }
    
    private static HashMap<String, String> splitRegistryValuePath(String path){
        
        HashMap<String, String> map = new HashMap<String, String>();
        
        map.put("hkey", path.substring(0,path.indexOf("\\")));
        map.put("key", path.substring(path.indexOf("\\") + 1, path.lastIndexOf("\\")));
        map.put("value", path.substring(path.lastIndexOf("\\") + 1,path.length()));
        
        return map;
        
    }
    
    public static boolean registryKeyExists(String registryKeyPath){

        Map<String, String> regMap = splitRegistryKeyPath(registryKeyPath);
        
        boolean valueExists = false;
        try{
            valueExists = Advapi32Util.registryKeyExists(getHKEY(regMap.get("hkey")),regMap.get("key"));
        }catch(Exception exception){
            
        }
        return  valueExists;
    }
    
    public static boolean registryValueExists(String registryValuePath){

        Map<String, String> regMap = splitRegistryValuePath(registryValuePath);
        
        boolean valueExists = false;
        try{
            valueExists = Advapi32Util.registryValueExists(getHKEY(regMap.get("hkey")),regMap.get("key"),regMap.get("value"));
        }catch(Exception exception){
            
        }
        return  valueExists;
    }
    
    public static String getStringValue(String registryValuePath){
        
        Map<String, String> regMap = splitRegistryValuePath(registryValuePath);
        
        String value = "";
        try{
            value = Advapi32Util.registryGetStringValue(getHKEY(regMap.get("hkey")),regMap.get("key"), regMap.get("value"));
            
        }catch(Exception exception){
            
        }
         
         return value;
    }
    
    public static int getDWORDValue(String registryValuePath){
        
        Map<String, String> regMap = splitRegistryValuePath(registryValuePath);
        
        int value = 0;
        try{
            
            Advapi32Util.registryGetIntValue(getHKEY(regMap.get("hkey")),regMap.get("key"), regMap.get("value"));
            
        }catch(Exception exception){
            
        }
        return value;
    }
    
    public static String[] getSubKeys(String registryKeyPath){
        
        Map<String, String> regMap = splitRegistryKeyPath(registryKeyPath);
        String[] subkeys = {};
        
        try{
            
            subkeys = Advapi32Util.registryGetKeys(getHKEY(regMap.get("hkey")),regMap.get("key"));
            
        }catch(Exception exception){
            
        }
        return subkeys;
    }

}



