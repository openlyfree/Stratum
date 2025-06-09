package com.ethn;


import java.io.FileWriter;
import java.io.IOException;
import java.io.File;
import io.quarkus.runtime.Quarkus;
import io.quarkus.runtime.annotations.QuarkusMain;

@QuarkusMain
public class Main{
    
    public static void main(String[] args) {

        String jk = System.getProperty("user.dir")+File.separator+"Stratum"+File.separator+"browser.txt";
        try (FileWriter writer = new FileWriter(jk)) {
            writer.write(args[0] != null? args[0] : "f"); // Write the text to the file
            
        } catch (IOException e) {
            // Catch any IOException that might occur during file operations
            System.err.println("An error occurred while writing to the file: " + e.getMessage());
            e.printStackTrace(); // Print the stack trace for debugging
        }

        jk = System.getProperty("user.dir")+File.separator+"Stratum"+File.separator+"password.txt";
        try (FileWriter writer = new FileWriter(jk)) {
            writer.write(args[1] != null? args[1] : "adminaccesskey789"); // Write the text to the file
            
        } catch (IOException e) {
            // Catch any IOException that might occur during file operations
            System.err.println("An error occurred while writing to the file: " + e.getMessage());
            e.printStackTrace(); // Print the stack trace for debugging
        }
        Quarkus.run(args);
        
    }

   
    
}