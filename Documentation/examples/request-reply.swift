// Request-Reply Pattern Example
// This shows a simple REQ-REP pattern between a client and server

// Server Code (REP)
import szq
import Foundation

// In a real application, you would run the server and client in separate processes

func runServer() {
    do {
        let context = Context()
        
        // Create a REP socket
        let server = try context.bind(type: .rep, url: "tcp://*:5555")
        
        print("Server started, waiting for requests...")
        
        while true {
            // Wait for a request
            guard let messages = try server.recvAll() else {
                print("No message received")
                continue
            }
            
            // Print the request
            if let requestString = messages[0].string {
                print("Received request: \(requestString)")
            }
            
            // Sleep to simulate work
            Thread.sleep(forTimeInterval: 0.5)
            
            // Send a reply
            try server.send(Message(string: "World"))
        }
    } catch {
        print("Server error: \(error)")
    }
}

// Client Code (REQ)
func runClient() {
    do {
        let context = Context()
        
        // Create a REQ socket
        let client = try context.connect(type: .req, url: "tcp://localhost:5555")
        
        // Configure some socket options
        // Set a send timeout (1 second)
        try client.setSendTimeout(milliseconds: 1000)
        
        // Set a receive timeout (2 seconds)
        try client.setReceiveTimeout(milliseconds: 2000)
        
        // Send 5 requests
        for i in 1...5 {
            print("Sending request \(i)...")
            
            // Send a request
            try client.send(Message(string: "Hello"))
            
            // Wait for a reply
            if let messages = try client.recvAll(), let replyString = messages[0].string {
                print("Received reply \(i): \(replyString)")
            } else {
                print("No reply received for request \(i)")
            }
            
            // Wait before next request
            Thread.sleep(forTimeInterval: 1.0)
        }
    } catch {
        print("Client error: \(error)")
    }
}

// For demo purposes, run the server in a separate thread
DispatchQueue.global().async {
    runServer()
}

// Wait a moment for the server to start
Thread.sleep(forTimeInterval: 1.0)

// Run the client
runClient()