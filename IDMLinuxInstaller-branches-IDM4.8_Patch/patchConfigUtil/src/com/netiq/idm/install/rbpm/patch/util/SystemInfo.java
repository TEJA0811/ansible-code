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

public final class SystemInfo {
     
     
     private SystemInfo(){
         
         throw new AssertionError("Default construction has been suppressed for non-instantiability.");
     }
     
     
     public static String getOSArchitecture(){
         
         String osArchitecture = null;
         
         // Get operating system Architecture
         if(isWindowsOS()){
             String arch = System.getenv("PROCESSOR_ARCHITECTURE");
             String wow64Arch = System.getenv("PROCESSOR_ARCHITEW6432");
             osArchitecture = (arch.endsWith("64") || arch.endsWith("64t")) || (wow64Arch != null && (wow64Arch.endsWith("64") || wow64Arch.endsWith("64t"))) ? "64bit" : "32bit";
         }
         else if(isLinuxOS()){
             
             try{
                 
                 LinuxShell shell = new LinuxShell("sh");
                 String command = "uname -i";
                 shell.stdin.write(command);
                 shell.waitFor();
                 String output = shell.stdout.readLine();
                
                 String[] lines = output.split("\n");
                 osArchitecture = lines[0];
                 
             }catch(Exception e){
                    e.printStackTrace();
            }

         }
         
         return osArchitecture;
         
     }
     
     
    public static boolean isWindowsOS() {

        return (System.getProperty("os.name").toLowerCase().indexOf("win") >= 0);

    }
    
    public static boolean isLinuxOS() {

        return (System.getProperty("os.name").toLowerCase().indexOf("nux") >= 0 );

    }
    
    public static boolean is64bitOS(){
        return (getOSArchitecture() == "64bit");
    }
    
   public static String getProgramFilesFolder(){
       return System.getenv("ProgramFiles");
   }
   
   public static String getProgramFilesX86Folder(){
       return System.getenv("ProgramFiles(x86)");
   }
    
}

