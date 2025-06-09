package com.ethn;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/server")
public class ServerResource {

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Path("/{name}")
    public Map<String, String> Settings(@PathParam("name") String name) {
        Map<String, String> result = new HashMap<>();
        Server s = Server.findById(name);
        if (s == null) {
            result.put("Message", "That server doesn't exist");
            return result;
        }
        File sf = new File(s.getJarPath()).getParentFile();
        System.out.println(sf.getAbsolutePath() + File.separator + "server.properties");
        File sfp = new File(sf.getAbsolutePath() + File.separator + "server.properties");
        if (sfp.exists()) {
            try (FileInputStream fis = new FileInputStream(sfp)) {
                Properties props = new Properties();
                props.load(fis);
                for (String key : props.stringPropertyNames()) {
                    result.put(key, props.getProperty(key));
                }
            } catch (Exception e) {
                result.put("Error", "Failed to read server.properties: " + e.getMessage());
            }
        } else {
            result.put("Message", "Please start the server once so server.properties is generated");
        }

        return result;
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Path("/{name}/{setting}/{newval}")
    public Map<String, String> SettingEdit(@PathParam("name") String name, @PathParam("setting") String setting,
            @PathParam("newval") String newval) {
        Map<String, String> result = new HashMap<>();
        Server s = Server.findById(name);
        if (s == null) {
            result.put("Message", "That server doesn't exist");
            return result;
        }

        File sf = new File(s.getJarPath()).getParentFile();
        System.out.println(sf.getAbsolutePath() + File.separator + "server.properties");
        File sfp = new File(sf.getAbsolutePath() + File.separator + "server.properties");

        if (sfp.exists()) {
            try (FileInputStream fis = new FileInputStream(sfp)) {
                Properties props = new Properties();
                props.load(fis);

                if (props.getProperty(setting) != null) {
                    props.setProperty(setting, newval);
                    try (FileOutputStream fos = new FileOutputStream(sfp)) {
                        props.store(fos, null);
                    } catch (Exception e) {
                        result.put("Error", "Failed to save server.properties: " + e.getMessage());
                        return result;
                    }
                } else {
                    result.put("Error", "That property doesn't exist");
                    return result;
                }

            } catch (Exception e) {
                result.put("Error", "Failed to edit server.properties: " + e.getMessage());
                return result;
            }
        } else {
            result.put("Message", "Please start the server once so server.properties is generated");
            return result;
        }

        result.put("Message", "Value Changed");
        return result;
    }

    @GET
    @Path("/{name}/console")
    public List<String> LScons(@PathParam("name") String SerName) {
        Server ser = Server.findById(SerName);
        if (ser == null) {
            return java.util.Collections.emptyList();

        }

        return ser.Console;
    }

    @Inject
    ServerService serverService;

    @GET
    @Path("/{name}/command/{cmdToRun}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response runCmd(@PathParam("name") String serverName,
            @PathParam("cmdToRun") String cmdToRun) {

        // Input validation
        if (serverName == null || serverName.trim().isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Server name is required\"}")
                    .build();
        }

        if (cmdToRun == null || cmdToRun.trim().isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Command is required\"}")
                    .build();
        }

        try {
            Server server = Server.findById(serverName);

            if (server == null) {
                return Response.status(Response.Status.NOT_FOUND)
                        .entity("{\"error\": \"Server not found\"}")
                        .build();
            }

            // Check if server is running
            if (server.getState() != "U") {
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity("{\"error\": \"Server is not running\"}")
                        .build();
            }

            // Get output stream from ServerService
            OutputStream outputStream = serverService.getServerOutputStream(serverName);

            if (outputStream == null) {
                return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                        .entity("{\"error\": \"Server output stream not available\"}")
                        .build();
            }

            // Add newline to ensure command is executed
            String commandWithNewline = cmdToRun + "\n";
            outputStream.write(commandWithNewline.getBytes(StandardCharsets.UTF_8));
            outputStream.flush();

            return Response.ok()
                    .entity("{\"message\": \"Command sent successfully\"}")
                    .build();

        } catch (IOException e) {
            // Log the error (use proper logging framework)
            System.err.println("Error writing to server output stream: " + e.getMessage());

            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"Failed to send command to server\"}")
                    .build();
        } catch (Exception e) {
            // Log the error
            System.err.println("Unexpected error: " + e.getMessage());

            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"Internal server error\"}")
                    .build();
        }
    }

}
