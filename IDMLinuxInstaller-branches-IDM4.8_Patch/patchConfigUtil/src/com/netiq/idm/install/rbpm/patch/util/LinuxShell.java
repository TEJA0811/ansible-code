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
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

//import com.netiq.idm.install.rbpm.patch.actions.LogInstallInfoAction;
//import com.zerog.ia.api.pub.IASys;

public final class LinuxShell
{
    public Process p;
    public OutputStreamWriter stdin;
    public BufferedReader stdout, stderr;

    public LinuxShell(String cmd) throws IOException
    {
        p = Runtime.getRuntime().exec(cmd);
        initShellCommand();
    }

    public LinuxShell(String[] cmd) throws IOException
    {
        p = Runtime.getRuntime().exec(cmd);
        initShellCommand();
    }
    
    private void initShellCommand() {
        // This sleep is to work around a bug in JVM 1.4.1 on Linux/Solaris.
        // We need to give up control before calling getOutputStream().
        try {
            Thread.sleep(5);
        }
        catch (Exception e) {}
        stdin = new OutputStreamWriter(p.getOutputStream());
        stdout = new BufferedReader(new InputStreamReader(p.getInputStream()));
        stderr = new BufferedReader(new InputStreamReader(p.getErrorStream()));
    }

    public void waitFor()
    {
        try {
            stdin.close();
        }
        catch (IOException e) {
            
        }
        try {
            
            p.waitFor();
            
        }
        catch (InterruptedException e) {
            
        }
    }

    public int exitValue()
    {
        try {
            return p.exitValue();
        }
        catch (IllegalThreadStateException e) {
            
        }
        return -1;
    }

    // Write output to System.out, which is ignored by IA
    public void eatOutput()
    {
        Thread thread = new Thread() {
            public void run() {
                int c;
                try {
                    while ((c = stdout.read()) >= 0) {
                        System.out.write(c);
                    }
                }
                catch (IOException e) {
                    System.out.println("IOException caught"); //$NON-NLS-1$
                    e.printStackTrace();
                }
            }
        };
        thread.start();
    }
    

    public void feedInput(String text)
    {
        
        try {
            if (text == null) {
                stdin.close();
            }
            else {
                stdin.write(text+"\n"); //$NON-NLS-1$
            }
        }
        catch (IOException ex) {
            
        }
    }

    // Write output to System.err, which is ignored by IA
    public void eatErrorOutput()
    {
        Thread thread = new Thread() {
            public void run() {
                int c;
                try {
                    while ((c = stderr.read()) >= 0) {
                        System.err.write(c);
                    }
                }
                catch (IOException ex) {
                    
                }
            }
        };
        thread.start();
    }
}


