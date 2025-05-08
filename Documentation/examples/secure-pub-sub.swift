// Secure Publish-Subscribe Pattern Example with CURVE security
// This demonstrates a secure PUB-SUB pattern using CURVE encryption

import szq
import Foundation

// In a real application, you would run the publisher and subscribers in separate processes
// Keys would be stored securely and distributed through a secure channel

func runSecurePublisher() {
    do {
        let context = Context()
        
        // Create a PUB socket
        let publisher = try context.bind(type: .pub, url: "tcp://*:5566")
        
        // Generate keys for the server
        guard let (pubKey, secretKey) = Z85.generateKeyPair() else {
            print("Failed to generate CURVE keys")
            return
        }
        
        print("Publisher public key: \(pubKey)")
        
        // Set up CURVE security on the publisher
        try publisher.setCurveServer(1) // Enable CURVE security in server mode
        try publisher.setCurvePublicKey(pubKey)
        try publisher.setCurveSecretKey(secretKey)
        
        print("Secure publisher started, sending updates...")
        
        var updateNumber = 0
        while updateNumber < 20 { // Send 20 updates then exit
            // Create update message
            let message = "Secure update #\(updateNumber)"
            
            // Publish the message
            try publisher.send(Message(string: message))
            print("Published: \(message)")
            
            updateNumber += 1
            Thread.sleep(forTimeInterval: 0.5)
        }
    } catch {
        print("Publisher error: \(error)")
    }
}

func runSecureSubscriber(id: Int, serverPublicKey: String) {
    do {
        let context = Context()
        
        // Create a SUB socket
        let subscriber = try context.connect(type: .sub, url: "tcp://localhost:5566")
        
        // Generate keys for the client
        guard let (clientPublicKey, clientSecretKey) = Z85.generateKeyPair() else {
            print("Failed to generate CURVE keys")
            return
        }
        
        // Set up CURVE security on the subscriber
        try subscriber.setCurvePublicKey(clientPublicKey)
        try subscriber.setCurveSecretKey(clientSecretKey)
        try subscriber.setCurveServerKey(serverPublicKey) // Must know the publisher's public key
        
        // Subscribe to all messages
        try subscriber.subscribe(prefix: "")
        
        // Set receive timeout
        try subscriber.setReceiveTimeout(milliseconds: 5000)
        
        print("Secure subscriber \(id) started, waiting for updates...")
        
        // Receive loop
        while true {
            // Wait for a message
            if let messages = try subscriber.recvAll(), let updateString = messages[0].string {
                print("Subscriber \(id) received: \(updateString)")
            } else {
                // No messages received within timeout
                print("Subscriber \(id) timed out waiting for messages")
                break
            }
        }
    } catch {
        print("Subscriber \(id) error: \(error)")
    }
}

// Generate and store server public key
var serverPublicKey = ""

// Start the publisher and get its public key
DispatchQueue.global().async {
    // Generate keys for the server (simulating a separate process)
    if let (pubKey, _) = Z85.generateKeyPair() {
        serverPublicKey = pubKey
        print("Generated server public key: \(serverPublicKey)")
        
        // Run the secure publisher
        runSecurePublisher()
    }
}

// Wait for publisher to start and keys to be generated
Thread.sleep(forTimeInterval: 2.0)

if !serverPublicKey.isEmpty {
    // Create multiple secure subscribers
    for i in 1...3 {
        DispatchQueue.global().async {
            runSecureSubscriber(id: i, serverPublicKey: serverPublicKey)
        }
    }
    
    // Wait for everything to complete
    Thread.sleep(forTimeInterval: 15.0)
    print("Secure example completed")
} else {
    print("Failed to generate server key")
}