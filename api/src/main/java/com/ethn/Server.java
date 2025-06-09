package com.ethn;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream; // Added for graceful stop
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.firefox.FirefoxOptions;
import org.openqa.selenium.firefox.FirefoxProfile;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

// Consider adding WebDriverManager for automatic driver setup:
// import io.github.bonigarcia.wdm.WebDriverManager;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

@Entity
@Table(name = "Servers")
public class Server extends PanacheEntityBase {
    @Id
    @Column(length = 255, nullable = false)
    private String name;
    @Column(name = "State")
    private String state;
    @Column(name = "created_at", columnDefinition = "TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createdAt;
    @Column(name = "loader")
    private String loader;
    @Column(name = "jarpath")
    private String jarPath;
    @Column(name = "PID")
    Integer PID;
    @Transient
    ArrayList<String> Console = new ArrayList<String>();

    @Transient
    ProcessBuilder processBuilder = new ProcessBuilder();
    @Transient
    Process serProcess;
    @Transient
    OutputStream serverOutputStream; // To send commands to the server

    public Server() {

    }

    public Server(String name, String loader) {
        this.name = name;
        this.createdAt = LocalDateTime.now();
        this.loader = loader;
        this.state = "D";
        try {
            this.init();
        } catch (Exception e) {
            System.out.println(e);
        }

    }

    void init() {

        this.state = "I"; // 'I' for Initializing
        String serverDownloadDir = System.getProperty("user.dir") + File.separator + "Stratum" + File.separator
                + "Servers" + File.separator
                + this.name;
        File downloadDirectory = new File(serverDownloadDir);

        // Try to find the JAR first
        this.jarPath = findJarFile(downloadDirectory);

        if (this.jarPath == null) {
            System.out.println("JAR not found locally. Attempting to download...");
            getServerJars(this.name, this.loader);
            // After attempting download, try to find the JAR again
            this.jarPath = findJarFile(downloadDirectory);
        }

        if (this.jarPath == null) {
            throw new RuntimeException("Failed to find or download server JAR for " + name);
        }
        this.state = "D"; // 'D' for Downloaded/Ready

        // 'D' for Downloaded/Ready
    }

    // Helper method to find the JAR file in the server's directory
    String findJarFile(File directory) {
        if (directory.exists() && directory.isDirectory()) {
            File[] files = directory.listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isFile() && file.getName().toLowerCase().endsWith(".jar")
                            && !file.getName().contains("installer")) {
                        // Exclude installer JARs if they are present after download
                        return file.getAbsolutePath();
                    }
                }
            }
        }
        return null; // No JAR found
    }

    void getServerJars(String serverName, String serverType) {
        char browser = 'c';
        String configdir = System.getProperty("user.dir") + File.separator + "Stratum" + File.separator+"browser.txt";
        File file = new File(configdir);
        try (BufferedReader reader = new BufferedReader(new FileReader(configdir))) {
            System.out.println("\nContent of " + file.getName() + ":");
            browser = reader.readLine().charAt(0);      
        } catch (IOException e) {
            System.err.println("Error reading file: " + e.getMessage());
        }
        System.out.println(String.format("Downloading %s server jar for %s...", serverType, serverName));

        String currentDirectory = System.getProperty("user.dir");
        String downloadPath = currentDirectory +File.separator+ "Stratum" +File.separator + "Servers" + File.separator + serverName;

        File downloadDir = new File(downloadPath);
        if (!downloadDir.exists()) {
            downloadDir.mkdirs();
        }

        WebDriver driver = null;
        try {
            switch (browser) {
                case 'f':
                    // WebDriverManager.firefoxdriver().setup(); // Uncomment if using
                    // WebDriverManager
                    FirefoxOptions firefoxOptions = new FirefoxOptions();
                    firefoxOptions.addArguments("--headless");

                    FirefoxProfile profile = new FirefoxProfile();
                    profile.setPreference("browser.download.folderList", 2);
                    profile.setPreference("browser.download.dir", downloadPath);
                    profile.setPreference("browser.download.manager.showWhenStarting", false);
                    profile.setPreference("browser.helperApps.neverAsk.saveToDisk", "application/java-archive");

                    firefoxOptions.setProfile(profile);
                    driver = new FirefoxDriver(firefoxOptions);
                    break;
                case 'c':
                    // WebDriverManager.chromedriver().setup(); // Uncomment if using
                    // WebDriverManager
                    ChromeOptions chromeOptions = new ChromeOptions();
                    chromeOptions.addArguments("--headless=new");
                    chromeOptions.addArguments("--disable-gpu");
                    chromeOptions.addArguments("--no-sandbox");

                    Map<String, Object> prefs = new HashMap<>();
                    prefs.put("download.default_directory", downloadPath);
                    prefs.put("download.prompt_for_download", false);
                    prefs.put("download.directory_upgrade", true);
                    prefs.put("safeBrowse.enabled", true);
                    chromeOptions.setExperimentalOption("prefs", prefs);

                    driver = new ChromeDriver(chromeOptions);
                    break;
                default:
                    System.out.println("Unsupported browser type: " + browser + ". Defaulting to Firefox.");
                    // WebDriverManager.firefoxdriver().setup(); // Uncomment if using
                    // WebDriverManager
                    driver = new FirefoxDriver(); // Fallback to a default Firefox if specified browser is unknown
                    break;
            }

            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(30)); // Increased wait time

            switch (serverType.toLowerCase()) {
                case "paper":
                    driver.get("https://papermc.io/downloads/all");
                    WebElement paperDownloadButton = wait.until(ExpectedConditions.presenceOfElementLocated(
                            By.xpath("/html/body/div/main/div/div[2]/div/table/tbody/tr[1]/td[4]/div/div/a")));
                    paperDownloadButton.click();
                    System.out.println("Paper server download initiated.");
                    break;
                case "fabric":
                    driver.get("https://fabricmc.net/use/server/");
                    WebElement fabricDownloadButton = wait.until(ExpectedConditions.presenceOfElementLocated(
                            By.xpath("/html/body/main/div/article/div/div[1]/main/div[1]/div[4]/a")));
                    fabricDownloadButton.click();
                    System.out.println("Fabric server download initiated.");
                    break;
                default:
                    System.out.println("Unsupported server type: " + serverType);
                    break;
            }

            try {
                Thread.sleep(10000); // 10 seconds for download to complete
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                System.err.println("Thread interrupted during download wait: " + e.getMessage());
            }
        } catch (Exception e) {
            System.err.println("An error occurred during server JAR download: " + e.getMessage());
            e.printStackTrace();
            throw e; // Re-throw to be caught by the calling thread's try-catch
        } finally {
            if (driver != null) {
                driver.quit(); // Always close the browser
                System.out.println("Browser closed.");
            }
        }
    }

    void run() {
        if (this.jarPath == null) {

        }

        File dir = new File(jarPath).getParentFile();
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

        processBuilder.command("java", "-Xmx1024M", "-Xms1024M", "-jar", jarPath, "nogui"); // Added -Xmx/-Xms and nogui
        processBuilder.directory(dir);
        processBuilder.redirectErrorStream(true); // Redirects error stream to standard output

        if (this.state != "U") { // Only run if not already running
            this.state = "U"; // 'U' for running/up
            try {
                serProcess = processBuilder.start();
                serverOutputStream = serProcess.getOutputStream();
                // Get output stream to send commands
                PID = (int) serProcess.pid();
                // Asynchronously read server output to prevent buffer overflow
                new Thread(() -> {
                    try (InputStream inputStream = serProcess.getInputStream()) {
                        byte[] buffer = new byte[1024];
                        int bytesRead;
                        while ((bytesRead = inputStream.read(buffer)) != -1) {
                            System.out.print(new String(buffer, 0, bytesRead));
                            Console.add(new String(buffer, 0, bytesRead));
                        }
                    } catch (IOException e) {
                        // This typically happens when the process ends
                        System.err.println("Error reading server output for " + name + ": " + e.getMessage());
                    }
                }).start();

                System.out.println("Server " + name + " started.");
            } catch (IOException e) {
                System.err.println("Failed to start server " + name + ": " + e.getMessage());
                e.printStackTrace();
                this.state = "D";
                if (serProcess != null) {
                    serProcess.destroyForcibly(); // Ensure process is cleaned up
                }
            }
        } else {
            System.out.println("Server " + name + " is already running.");
        }

    }

    void stop() {

        if (this.PID == null) {
            System.err.println("PID cannot be null or empty.");
            return;
        }

        String os = System.getProperty("os.name").toLowerCase();
        String command = null;

        if (os.contains("win")) {
            // Windows: taskkill /F /PID <PID>
            // /F for forceful, /PID specifies the process ID
            command = "taskkill /F /PID " + this.PID;
            System.out.println("Attempting to stop process (Windows) with command: " + command);
        } else if (os.contains("nix") || os.contains("nux") || os.contains("mac")) {
            // Linux/macOS: kill -9 <PID>
            // -9 for SIGKILL (forceful termination)
            command = "kill -9 " + this.PID;
            System.out.println("Attempting to stop process (Linux/macOS) with command: " + command);
        } else {
            System.err.println("Unsupported operating system: " + os);
            return;
        }

        try {
            ProcessBuilder pb;
            if (os.contains("win")) {
                pb = new ProcessBuilder("cmd.exe", "/c", command);
            } else {
                pb = new ProcessBuilder("sh", "-c", command);
            }
            Process process = pb.start();
            int exitCode = process.waitFor();

            if (exitCode == 0) {
                System.out.println("Process with PID " + this.PID + " terminated successfully.");
            } else {

                String errorOutput;
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()))) {
                    errorOutput = reader.lines().collect(Collectors.joining("\n"));
                }
                System.err.println("Failed to terminate process with PID " + this.PID + ". Exit code: " + exitCode);
                if (!errorOutput.isEmpty()) {
                    System.err.println("Error output: " + errorOutput);
                }
            }

        } catch (IOException | InterruptedException e) {
            System.err.println("An error occurred while trying to stop the process: " + e.getMessage());
            e.printStackTrace();
        }
        if (this.state == "U") {
            this.state = "D";
        }

    }

    void remove() {
        if (this.state == "U") {
            this.stop(); // Stop before removing
        }
        try {
            File dir = new File(jarPath).getParentFile();
            if (dir.exists()) {
                // Recursively delete contents
                deleteDirectory(dir);
            }
        } catch (Exception e) {
            System.err.println("An error occurred while removing server files: " + e.getMessage());
            e.printStackTrace();
        }
        this.delete(); // Assuming this is a PanacheEntityBase method to delete from DB
        System.out.println("Server " + name + " removed from database.");
    }

    private void deleteDirectory(File directory) {
        File[] allContents = directory.listFiles();
        if (allContents != null) {
            for (File file : allContents) {
                deleteDirectory(file);
            }
        }
        if (directory.delete()) {
            System.out.println("Deleted: " + directory.getAbsolutePath());
        } else {
            System.err.println("Failed to delete: " + directory.getAbsolutePath());
        }
    }

    // --- GETTERS ---
    public String getName() {
        return name;
    }

    public Integer getPID() {
        return PID;
    }

    public String getState() {
        return state;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public String getLoader() {
        return loader;
    }

    public String getJarPath() {
        return jarPath;
    }

    public ArrayList<String> getConsole() {
        return Console;
    }

    public void setState(String c) {
        this.state = c;
        try {
            this.persist();
        } catch (Exception e) {
            System.out.println(420);
        }

    }

    public void setJarPath(String s) {
        this.jarPath = s;
        try {
            this.persist();
        } catch (Exception e) {
            System.out.println(430);
        }

    }

}