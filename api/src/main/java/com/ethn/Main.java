package com.ethn;


import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;

import org.eclipse.microprofile.config.ConfigProvider;

import java.io.File;
import io.quarkus.runtime.Quarkus;
import io.quarkus.runtime.annotations.QuarkusMain;

@QuarkusMain
public class Main{
    
    public static void main(String[] args) {
        try {
            // Get the JDBC URL directly from the configuration provider.
            // We use getOptionalValue to safely retrieve the property,
            // as it might not be present in all environments.
            Optional<String> jdbcUrlOptional = ConfigProvider.getConfig().getOptionalValue("quarkus.datasource.jdbc.url", String.class);

            if (jdbcUrlOptional.isPresent()) {
                String jdbcUrl = jdbcUrlOptional.get();

                // Check if the URL is for SQLite to apply this logic only when relevant.
                if (jdbcUrl.startsWith("jdbc:sqlite:")) {
                    // Extract the file path by removing the "jdbc:sqlite:" prefix.
                    // Example: "jdbc:sqlite:/Users/ethan/Desktop/Coding/Stratum/api/Stratum/Servers.db"
                    // becomes "/Users/ethan/Desktop/Coding/Stratum/api/Stratum/Servers.db"
                    String filePathString = jdbcUrl.replace("jdbc:sqlite:", "");

                    // Convert the file path string to a Path object.
                    Path dbFilePath = Paths.get(filePathString);

                    // Get the parent directory of the database file.
                    // Example: "/Users/ethan/Desktop/Coding/Stratum/api/Stratum"
                    Path dbDirectoryPath = dbFilePath.getParent();

                    // Check if the parent directory exists and is not null (e.g., if the path was just a file name).
                    if (dbDirectoryPath != null && !Files.exists(dbDirectoryPath)) {
                        // Create all nonexistent parent directories as well.
                        Files.createDirectories(dbDirectoryPath);
                        System.out.println("Successfully created database directory: " + dbDirectoryPath.toAbsolutePath());
                    } else if (dbDirectoryPath == null) {
                        System.err.println("Warning: Database path is a root path or invalid: '" + filePathString + "'. Cannot create parent directory automatically.");
                    } else {
                        System.out.println("Database directory already exists: " + dbDirectoryPath.toAbsolutePath());
                    }
                } else {
                    System.err.println("Warning: Configured JDBC URL is not an SQLite URL. Skipping directory creation logic for: " + jdbcUrl);
                }
            } else {
                System.err.println("Warning: 'quarkus.datasource.jdbc.url' property not found in configuration. Skipping database directory creation.");
            }
        } catch (IOException e) {
            // Log the error and re-throw a RuntimeException to prevent the application from starting
            // if the directory cannot be created (e.g., due to permissions).
            System.err.println("FATAL ERROR: Failed to create database directory during application startup: " + e.getMessage());
            e.printStackTrace(); // Print full stack trace for detailed debugging
            throw new RuntimeException("Application startup failed due to database directory creation error.", e);
        }

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