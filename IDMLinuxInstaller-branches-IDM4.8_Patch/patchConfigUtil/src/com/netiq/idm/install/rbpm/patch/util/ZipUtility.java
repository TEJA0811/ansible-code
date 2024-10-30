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


import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;
 
/**
 * This utility extracts files and directories of a standard zip file to
 * a destination directory.
 * @author www.codejava.net
 *
 */
public class ZipUtility {
    
    /**
     * Describe <code>createZip</code> method here.
     * @param zipName a <code>String</code> value
     * @param srcDirName a <code>String</code> value
     * @exception java.io.IOException if an error occurs
     */
    public static void createZip(String targetZipFilePath,
                                 String sourceDirPath)
        throws IOException
    {
        File zipFile = new File(targetZipFilePath);
        File srcDir = new File(sourceDirPath);

        OutputStream fileOut = new FileOutputStream(zipFile);
        ZipOutputStream zipOut = new ZipOutputStream(fileOut);

        createZip(zipOut, srcDir, sourceDirPath);
        zipOut.flush();
        zipOut.finish();
    }


    /**
     * Describe <code>createZip</code> method here.
     * @param zipOut a <code>ZipOutputStream</code> value
     * @param directory a <code>File</code> value
     * @param srcDirName a <code>String</code> value
     * @exception java.io.IOException if an error occurs
     */
    public static void createZip(ZipOutputStream zipOut,
                                 File directory,
                                 String srcDirName)
        throws IOException
    {
        File[] fileArray = directory.listFiles();
        byte buffer[] = new byte[1024];
        int bytesRead;

        for (int i = 0; i < fileArray.length; i++) {

            File currFile = fileArray[i];
            String currFilename = currFile.getName();
            String pathInZip = directory.getAbsolutePath();

            /*
             * Fixes the Java bug that doesn't handle Windows
             * separators.
             */
            pathInZip = pathInZip.replace('\\', '/');
            srcDirName = srcDirName.replace('\\', '/');
            /* Strips the parent dir leaving only the file path. */
            if (!(pathInZip.equals(srcDirName))) {
                try {
                    pathInZip = pathInZip.substring(srcDirName.length() + 1) +
                        "/" +
                        currFilename;
                } catch (StringIndexOutOfBoundsException siobe) {
                    System.out.println("\nEXCEPTION: " + siobe + ", " + pathInZip);
                    continue;
                }
            } else {
                pathInZip = currFilename;
            }

            /*
             * If this is a directory add a path separator which gets
             * around the ZipFile limitation of not adding empty dirs.
             */
            if (currFile.isDirectory()) {
                pathInZip = pathInZip + "/";
            }

            ZipEntry entry = new ZipEntry(pathInZip);
            zipOut.putNextEntry(entry);
            entry.setMethod(ZipEntry.DEFLATED);

            /*
             * This is for writing files to the zip/jar file. If it's a
             * directory 'fis' would throw an exception.
             */
            if ((!currFile.isDirectory())) {
                File file = new File(directory, currFilename);
                FileInputStream fis = new FileInputStream(file);
                while ((bytesRead = fis.read(buffer)) != -1) {
                    zipOut.write(buffer, 0, bytesRead);
                }
                fis.close();
            }
            zipOut.flush();
            zipOut.closeEntry();

            /* If this is a directory then recurse. */
            if (currFile.isDirectory()) {
                createZip(zipOut, currFile, srcDirName);

            }
        }
    }


    public static void unzipAll(File sourceZipFile,File destDirectory) throws IOException {
        //Open the ZIP file for reading
        ZipFile zipFile = new ZipFile(sourceZipFile, ZipFile.OPEN_READ);

       //Get the entries
        Enumeration<?> myEnum = zipFile.entries();

        while (myEnum.hasMoreElements()) {
            ZipEntry zipEntry = (ZipEntry) myEnum.nextElement();

            String currName = zipEntry.getName();

            File destFile = new File(destDirectory, currName);

            // grab file's parent directory structure
            File destinationParent = destFile.getParentFile();

            // create the parent directory structure if needed
            destinationParent.mkdirs();

            if (!zipEntry.isDirectory()) {
                BufferedInputStream is = new BufferedInputStream(zipFile.getInputStream(zipEntry));
                int currentByte;

                // write the current file to disk
                FileOutputStream fos = new FileOutputStream(destFile);
                BufferedOutputStream dest = new BufferedOutputStream(fos);

                // read and write until last byte is encountered
                while ((currentByte = is.read()) != -1) {
                    dest.write(currentByte);
                }
                dest.flush();
                dest.close();
                is.close();
            }
        }
        
        zipFile.close();
    }
}
