package com.ethn;


import java.util.HashMap;
import java.util.List;
import java.util.Map;

import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Path("/")
public class MainResource {
    @Inject // Inject the service that contains the transactional methods
    ServerService ServerService;

    private static final ExecutorService executor = Executors
            .newCachedThreadPool();

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Server> hello() {
        return Server.listAll();
    }

    @GET
    @Path("/add/{name}/{loader}")
    @Transactional
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, String> makeSer(
            @PathParam("name") String name,
            @PathParam("loader") String loader) {
        // Clean null bytes from input parameters
        String cleanName = name != null ? name.replace("\0", "") : null;
        String cleanLoader = loader != null ? loader.replace("\0", "") : null;

        Server u = new Server(cleanName, cleanLoader);
        try {
            u.persist();
        } catch (Exception e) {
            System.out.println(43);
        }
        
        Map<String, String> result = new HashMap<>();
        result.put("Message", "Done :)");
        return result;
    }

    @GET
    @Path("/del/{name}")
    @Transactional
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, String> delSer(@PathParam("name") String name) {
        Map<String, String> result = new HashMap<>();
        Server u = Server.findById(name);
        if (u == null) {
            result.put("Message", "That Server Doesn't Exist");
            return result;
        }
        u.remove();

        result.put("Message", "Done :)");
        return result;
    }

    @GET
    @Path("/run/{name}")
    @Transactional
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, String> runSer(@PathParam("name") String name) {
        Map<String, String> result = new HashMap<>();
        Server u = Server.findById(name);
        if (u == null) {
            return result;
        }
        executor.submit(() -> {
            ServerService.run(u.getName());
        });
        result.put("Message", "Done :)");
        return result;
    }

    @GET
    @Path("/stop/{name}")
    @Transactional
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, String> stopSer(@PathParam("name") String name) {
        Map<String, String> result = new HashMap<>();
        Server u = Server.findById(name);

        if (u == null) {
            result.put("Message", "That Server Doesn't Exist");
            return result;
        }
        u.stop();
        u.Console.clear();

        result.put("Message", "Done :)");
        return result;
    }

}
