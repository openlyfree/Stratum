package com.ethn;


import java.util.ArrayList;
import java.util.List;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;


public class ModResource {


    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<String> mods() {
        ArrayList<String> mod = new ArrayList<String>();
        


        return mod;
    }

  
}
