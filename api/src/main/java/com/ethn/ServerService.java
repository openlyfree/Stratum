package com.ethn;


import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

@ApplicationScoped
public class ServerService {

    // In-memory storage for output streams - cannot be persisted to database
    private final Map<String, OutputStream> serverOutputStreams = new ConcurrentHashMap<>();

    // Method to get output stream for a server
    public OutputStream getServerOutputStream(String serverName) {
        return serverOutputStreams.get(serverName);
    }

    @Transactional
    void run(String SerName) {
        Server ser = Server.findById(SerName);
        if (ser == null) {
            System.err.println("Server " + SerName + " not found");
            return;
        }

        if (ser.getJarPath() == null) {
            System.err
                    .println("Cannot run server " + ser.getName() + ". JAR path is not set. Attempting to initialize.");
            try {
                ser.init();
            } catch (RuntimeException e) {
                System.err.println("Failed to initialize server for run: " + e.getMessage());
                return;
            }
        }

        File dir = new File(ser.getJarPath()).getParentFile();
        if (!dir.exists()) {
            System.err.println("Server directory does not exist: " + dir.getAbsolutePath());
            return;
        }

        // --- EULA Handling ---
        File eulaFile = new File(dir, "eula.txt");
        if (!eulaFile.exists()) {
            try (java.io.FileWriter writer = new java.io.FileWriter(eulaFile)) {
                writer.write("eula=true\n");
                System.out.println("Created eula.txt with 'eula=true'.");
            } catch (IOException e) {
                System.err.println("Failed to create eula.txt: " + e.getMessage());
                // Don't proceed if EULA creation fails, as server won't start
                return;
            }
        }
        // --- End EULA Handling ---

        ser.processBuilder.command("java", "-Xmx1024M", "-Xms1024M", "-jar", ser.getJarPath(), "nogui");
        ser.processBuilder.directory(dir);
        ser.processBuilder.redirectErrorStream(true);

        if (ser.getState() != "U") { // Only run if not already running
            ser.setState("U"); // 'U' for running/up
            try {
                ser.serProcess = ser.serProcess != null ? ser.serProcess : ser.processBuilder.start();

                // Store output stream in memory (not in database)
                OutputStream outputStream = ser.serProcess.getOutputStream();
                serverOutputStreams.put(ser.getName(), outputStream);

                PIDPersist(ser.getName(), (int) ser.serProcess.pid());

                // Asynchronously read server output to prevent buffer overflow
                new Thread(() -> {
                    try (InputStream inputStream = ser.serProcess.getInputStream()) {
                        byte[] buffer = new byte[1024];
                        int bytesRead;
                        while ((bytesRead = inputStream.read(buffer)) != -1) {
                            String output = new String(buffer, 0, bytesRead);
                            ConsolePersist(ser.getName(), output);
                            System.out.println("Server " + ser.getName() + " output: " + output);
                        }
                    } catch (IOException e) {
                        // This typically happens when the process ends
                        System.err.println("Error reading server output for " + SerName + ": " + e.getMessage());
                    } finally {
                        // Clean up when process ends
                        serverOutputStreams.remove(SerName);
                        // Update server state to down
                        updateServerState(SerName, "D");
                    }
                }, "ServerOutput-" + ser.getName()).start();

                System.out.println("Server " + SerName + " started.");
            } catch (IOException e) {
                System.err.println("Failed to start server " + SerName + ": " + e.getMessage());
                e.printStackTrace();
                ser.setState("D");
                serverOutputStreams.remove(SerName); // Clean up
                if (ser.serProcess != null) {
                    ser.serProcess.destroyForcibly();
                }
            }
        } else {
            System.out.println("Server " + SerName + " is already running.");
        }
    }

    @Transactional
    void updateServerState(String serverName, String state) {
        Server ser = Server.findById(serverName);
        if (ser != null) {
            ser.setState(state);
            ser.persist();
        }
    }

    @Transactional
    void ConsolePersist(String SerName, String ToAdd) {
        Server ser = Server.findById(SerName);
        if (ser == null) {
            System.out.println("Server Doesn't Exist");
            return;
        }
        if (ser.Console == null) {
            // Initialize console list if null
            ser.Console = new java.util.ArrayList<>();
        }
        ser.Console.add(ToAdd);
        ser.persist();
    }

    @Transactional
    void PIDPersist(String SerName, int PID) {
        Server ser = Server.findById(SerName);
        if (ser == null) {
            System.out.println("Server Doesn't Exist");
            return;
        }
        ser.PID = PID;
        ser.persist();
    }

    

    

    

}