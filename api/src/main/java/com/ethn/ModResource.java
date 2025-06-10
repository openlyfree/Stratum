package com.ethn;



import io.quarkus.websockets.next.OnOpen;
import io.quarkus.websockets.next.OnTextMessage;
import io.quarkus.websockets.next.PathParam;
import io.quarkus.websockets.next.WebSocket;
import io.quarkus.websockets.next.WebSocketConnection;
import jakarta.inject.Inject;

@WebSocket(path = "/mods/{server}")
public class ModResource {
    @Inject
    WebSocketConnection connection;

    @OnOpen
    void OnOpen(@PathParam("server") String name){
        
    }

    @OnTextMessage
    void onTextMessage(String message, @PathParam("server") String name) {
        
    }


  
}
