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

import java.io.BufferedReader;
import java.io.InputStreamReader;

public final class WinCMD {
    
    
    private WinCMD(){
        
        throw new AssertionError("Default construction has been suppressed for non-instantiability.");
        
    }
    
    
    public static String executeCommand(String command){
        
        Process proc = null;
        StringBuilder output = new StringBuilder();
        
        try { 
            
            String[] commandArray = {"CMD","/C",command};
            
            ProcessBuilder pb = new ProcessBuilder(commandArray);
            pb.redirectErrorStream(true);
            
            /* Start the process */
            proc = pb.start();
            
            /* Read the process's output */ 
            
            BufferedReader stdout = new BufferedReader(new InputStreamReader( proc.getInputStream()));   
            
            String line = null;
            while ((line = stdout.readLine()) != null) {
                output.append(line + "\n");
            }
            
            stdout.close();

        }
        catch(Exception e) { 
            
        } 
        finally{
            proc.destroy();
        }
        
        return output.toString();
        
    }

}

