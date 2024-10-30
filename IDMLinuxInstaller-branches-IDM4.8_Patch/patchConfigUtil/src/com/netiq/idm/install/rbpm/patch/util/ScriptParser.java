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
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class ScriptParser {
    
    private static String m_SetEnvFilePath = "";
    private static ArrayList<String> m_envLines = null; //new ArrayList<String>(Arrays.asList(Util.readLines(fileName)));
    
    private ScriptParser(){
        throw new AssertionError("Default construction has been suppressed for non-instantiability.");
    }
    
     /**
     * Routine to read the lines of a file and return them in a String array.
     * @param filename The name of the file to read in
     * @return The file content as an array
     * @throws IOException Thrown if the file interaction causes an error.
     */
    private static String[] readLines(String filename) throws IOException
    {
        FileReader fileReader = new FileReader(filename);
        BufferedReader bufferedReader = new BufferedReader(fileReader);
        List<String> lines = new ArrayList<String>();
        String line;
        while ((line = bufferedReader.readLine()) != null) {
            lines.add(line);
        }
        bufferedReader.close();
        return lines.toArray(new String[lines.size()]);
    }
    
    private static boolean isEnclosedInQuotes(String envVal)
    {
        char initialChar = envVal.charAt(0);
        boolean retInd = (envVal != null && envVal.length() > 2 && (initialChar == 39 || initialChar == '"') &&
                initialChar == envVal.charAt(envVal.length() - 1));
        return retInd;
    }
    
    /**
     * Indicates if a string is empty (i.e. either null or has a length of zero).
     * @param val String to test
     * @return Returns true if the val was empty; false otherwise.
     */
    private static boolean isEmpty(String val)
    {
        return (val == null || val.length() == 0);
    }

    
    private static String retrieveContent(String envName, String keyName)
    {
        
        boolean isUnix = SystemInfo.isLinuxOS()?true:false;
        
        String commentChar = isUnix ? "#" : "rem";
         String envDecl = envName + "=";
         String propDecl = "-D" + keyName + "=";
         int envDeclEndPos = -1;
         String line = null;

         // Start search at the bottom of the file
         for (int i = m_envLines.size() - 1; i >= 0; i--) {
             line = m_envLines.get(i);
             if (line.toLowerCase().startsWith(commentChar)) {
                 line = null;
                 continue;
             }

             if (line.contains(envDecl)) {
                 envDeclEndPos = line.indexOf(envDecl) + envDecl.length();
                 break;
             }
             line = null;
         }

         String value = "";

         // env-var exists in file
         if (line != null) {
             // no keyName means assign entire line to new value
             if (keyName == null) {
                 value = (envDeclEndPos == line.length()) ? "" : line.substring(envDeclEndPos);
             } else {
                 int propPos = line.indexOf(propDecl, envDeclEndPos);

                 // property does not exist, so append
                 if (propPos != -1) {

                     // property does exist, so replace
                     int propEndPos = line.indexOf(" -", propPos + propDecl.length());
                     if (propEndPos == -1 && isEnclosedInQuotes(line.substring(envDeclEndPos))) {
                         // Apparently no trailing property, make sure value not enclosed in quotes
                         propEndPos = line.length() - 1;
                     }

                     if (propEndPos == -1) {
                         value = line.substring(propPos + propDecl.length());
                     } else {
                         value = line.substring(propPos + propDecl.length(), propEndPos);
                     }
                 }
             }
         }

         // remove enclosing quotes if present
         if (!isEmpty(value) && isEnclosedInQuotes(value)) {
             if (value.length() == 2) {
                 value = "";
             } else {
                 value = value.substring(1, value.length() - 1);
             }
         }
         return value;

    }
    
    public static void updateContent(String envName, String keyName, String val)
    {
        boolean isUnix = SystemInfo.isLinuxOS()?true:false; 
        
         String commentChar = isUnix ? "#" : "rem";
         String propQuote = isUnix ? "'" : "\"";
         String envDecl = envName + "=";
         String propDecl = "-D" + keyName + "=";
         int envDeclEndPos = -1;
         String line = null;
         int lineIndex = -1;

         // Start search at the bottom of the file
         for (int i = m_envLines.size() - 1; i >= 0; i--) {
             line = m_envLines.get(i);
             if (line.toLowerCase().startsWith(commentChar)) {
                 line = null;
                 continue;
             }

             if (line.contains(envDecl)) {
                 envDeclEndPos = line.indexOf(envDecl) + envDecl.length();
                 lineIndex = i;
                 break;
             }
             line = null;
         }

         // env-var exists in file
         if (line != null) {
             // no keyName means assign entire line to new value
             if (keyName == null) {
                 line = line.substring(0, envDeclEndPos) + val;
             } else {
                 int propPos = line.indexOf(propDecl, envDeclEndPos);

                 // property does not exist, so append
                 if (propPos == -1) {
                     if (isEnclosedInQuotes(line.substring(envDeclEndPos))) {
                         line = line.substring(0, line.length() - 1) + " " + propDecl + val + line.charAt(line.length() - 1);
                     } else {
                         line = line.substring(0, line.length()) + " " + propDecl + val;
                     }

                 } else {

                     // property does exist, so replace
                     int propEndPos = line.indexOf(" -", propPos + propDecl.length());
                     if (propEndPos == -1 && isEnclosedInQuotes(line.substring(envDeclEndPos))) {
                         // Apparently no trailing property, make sure value not enclosed in quotes
                         propEndPos = line.length() - 2;
                     }

                     if (propEndPos == -1) {
                         line = line.substring(0, propPos) + propDecl + val; 
                     } else {
                         line = line.substring(0, propPos) + propDecl + val + line.substring(propEndPos + 1);
                     }
                 }
             }
             m_envLines.set(lineIndex, line);
         } else {
             // Add env-var assignment since it does not exist in the file
             int insertPoint = -1;
             String assignStmt = isUnix ? "export " : "set ";
             StringBuilder newLine = new StringBuilder(assignStmt).append(envDecl);
             if (isUnix) {
                 newLine.append('"');
             }
             if (keyName != null) {
                 newLine.append(propDecl);
             }
             boolean valContainsSpace = val.contains(" ") && keyName != null;
             if (valContainsSpace) {
                 newLine.append(propQuote);
             }
             newLine.append(val);
             if (valContainsSpace) {
                 newLine.append(propQuote);
             }
             if (isUnix) {
                 newLine.append('"');
             } else {
                 // make sure to insert new line BEFORE an exit statement
                 insertPoint = indexOf(m_envLines, "exit ");
             }

             if (insertPoint == -1) {
                 m_envLines.add(newLine.toString());
             } else {
                 m_envLines.add(insertPoint, newLine.toString());
             }
         }
    }
    
    public static void removeContent(String envName, String keyName)
    {
        
        boolean isUnix = SystemInfo.isLinuxOS()?true:false;
        String commentChar = isUnix ? "#" : "rem";
        String envDecl = envName + "=";
        String propDecl = "-D" + keyName + "=";
        int envDeclEndPos = -1;
        String line = null;
        int lineIndex = -1;

        // Start search at the bottom of the file
        for (int i = m_envLines.size() - 1; i >= 0; i--) {
            line = m_envLines.get(i);
            if (line.toLowerCase().startsWith(commentChar)) {
                line = null;
                continue;
            }

            if (line.contains(envDecl)) {
                envDeclEndPos = line.indexOf(envDecl) + envDecl.length();
                lineIndex = i;
                break;
            }
            line = null;
        }

        // env-var exists in file
        if (line != null) {
            // no keyName means disable entire line
            if (keyName == null) {
                line = commentChar + " " + line;
            } else {
                int propPos = line.indexOf(propDecl, envDeclEndPos);

                // property does not exist, so append
                if (propPos != -1) {

                    // property does exist, so remove
                    int propEndPos = line.indexOf(" -D", propPos + propDecl.length());
                    if (propEndPos == -1 && isEnclosedInQuotes(line.substring(envDeclEndPos))) {
                        // Apparently no trailing property, make sure value not enclosed in quotes
                        propEndPos = line.length() - 2;
                    } else {
                        // crunch up spaces
                        if (line.charAt(propPos - 1) == ' ' && line.charAt(propEndPos) == ' ') {
                            propEndPos++;
                        }
                    }

                    if (propEndPos == -1) {
                        line = line.substring(0, propPos);
                    } else {
                        line = line.substring(0, propPos) + line.substring(propEndPos);
                    }
                }
            }
            m_envLines.set(lineIndex, line);
        }
    }
    
    public static int indexOf(ArrayList<String> envLines, String decl)
    {
        int retIndex = -1;
        String line;
        if (envLines != null) {
            for (int i = envLines.size() - 1; i >= 0; i--) {
                line = envLines.get(i);
                if (line.toLowerCase().startsWith(decl)) {
                    retIndex = i;
                    break;
                }
            }
        }
        return retIndex;
    }
    
    public static void writeLines(String filename, String[] lines) throws IOException
    {
        PrintWriter outputWriter = null;
        try {
            File outputFile = new File(filename);
            if (outputFile.exists() && !outputFile.delete()) {
                throw new IOException("Unable to delete " + filename);
            }
            outputWriter = new PrintWriter(outputFile, "UTF-8");
            for (String line : lines) {
                outputWriter.println(line);
            }
            outputWriter.flush();
        } finally {
            if (outputWriter != null) {
                outputWriter.close();
            }
        }
    }

    
    public static String getValue(String setEnvFilePath, String variable){
        
        if(m_SetEnvFilePath != setEnvFilePath){
            
            try {
                m_envLines = new ArrayList<String>(Arrays.asList(readLines(setEnvFilePath)));
            } catch (IOException e) {
                
                return null;
            }
        }
        
        
        return retrieveContent(variable,null);
        
    }
    
    public static String getValue(String setEnvFilePath, String variable, String key){
        
        if(m_SetEnvFilePath != setEnvFilePath){
            
            try {
                m_envLines = new ArrayList<String>(Arrays.asList(readLines(setEnvFilePath)));
            } catch (IOException e) {
                
                return null;
            }
        }
        
        
        return retrieveContent(variable,key);
        
    }
    
    public static void setValue(String setEnvFilePath, String variable, String value){
        
        if(m_SetEnvFilePath != setEnvFilePath){
            
            try {
                m_envLines = new ArrayList<String>(Arrays.asList(readLines(setEnvFilePath)));
            } catch (IOException e) {
                
                
            }
        }
        
        
        updateContent(variable,null,value);
        
        try {
            writeLines(setEnvFilePath,m_envLines.toArray(new String[m_envLines.size()]));
        } catch (IOException e) {
           
            e.printStackTrace();
        }
        
    }
    
    public static void setValue(String setEnvFilePath, String variable, String key, String value){
        
        if(m_SetEnvFilePath != setEnvFilePath){
            
            try {
                m_envLines = new ArrayList<String>(Arrays.asList(readLines(setEnvFilePath)));
            } catch (IOException e) {
                
                
            }
        }
        
        updateContent(variable,key,value);
        
        try {
            writeLines(setEnvFilePath,m_envLines.toArray(new String[m_envLines.size()]));
        } catch (IOException e) {
           
            e.printStackTrace();
        }
        
    }
    
   public static void remove(String setEnvFilePath, String variable){
        
        if(m_SetEnvFilePath != setEnvFilePath){
            
            try {
                m_envLines = new ArrayList<String>(Arrays.asList(readLines(setEnvFilePath)));
            } catch (IOException e) {
                
                
            }
        }
        
        
        removeContent(variable,null);
        
        try {
            writeLines(setEnvFilePath,m_envLines.toArray(new String[m_envLines.size()]));
        } catch (IOException e) {
           
            e.printStackTrace();
        }
        
    }
    
   public static void remove(String setEnvFilePath, String variable, String key){
        
        if(m_SetEnvFilePath != setEnvFilePath){
            
            try {
                m_envLines = new ArrayList<String>(Arrays.asList(readLines(setEnvFilePath)));
            } catch (IOException e) {
                
                
            }
        }
        
        
        removeContent(variable,key);
        
        try {
            writeLines(setEnvFilePath,m_envLines.toArray(new String[m_envLines.size()]));
        } catch (IOException e) {
           
            e.printStackTrace();
        }
        
    }
    
    
    

}
