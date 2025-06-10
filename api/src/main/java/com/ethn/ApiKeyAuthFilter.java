package com.ethn;

import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;

// Optional: If you only want to apply this filter to specific paths/resources,
// you would create a custom annotation and apply it. For now, @Provider makes it global.
@Provider
public class ApiKeyAuthFilter implements ContainerRequestFilter {

    private static final String API_KEY_HEADER = "Key"; // The name of your API key header
//TODO:ADD PASSWORD.txt reading stuff
    
    String validApiKey = "adminaccesskey789";

    @Override
    public void filter(ContainerRequestContext requestContext) {
        // Get the API key from the request header
        String apiKey = requestContext.getHeaderString(API_KEY_HEADER);

        // Check if the API key is missing or incorrect
        if (apiKey == null) {
            // If invalid, abort the request with a 401 Unauthorized response
            requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Missing API Key")
                    .build());
        } else if (!apiKey.equals(validApiKey)) {
            requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Invalid API Key")
                    .build());
        }
        // If the API key is valid, the filter finishes, and the request proceeds to the endpoint
    }
}