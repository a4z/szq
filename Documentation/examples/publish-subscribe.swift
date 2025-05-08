// Publish-Subscribe Pattern Example
// This demonstrates a PUB socket broadcasting messages to multiple SUB sockets

import szq
import Foundation

// In a real application, you would run the publisher and subscribers in separate processes

func runPublisher() {
    do {
        let context = Context()
        
        // Create a PUB socket
        let publisher = try context.bind(type: .pub, url: "tcp://*:5556")
        
        // Set high water mark for outgoing messages
        try publisher.setSendHighWaterMark(1000)
        
        // Set conflate option (only keep most recent message per topic)
        try publisher.setConflate(1)
        
        print("Publisher started, sending updates...")
        
        var updateNumber = 0
        while updateNumber < 20 { // Send 20 updates then exit
            // Create update categories
            let categories = ["sports", "weather", "news"]
            let category = categories[updateNumber % categories.count]
            
            // Create update message
            let message = "[\(category)] Update #\(updateNumber)"
            
            // Publish the message with a topic prefix
            try publisher.send(Message(string: "\(category) \(message)"))
            print("Published: \(message)")
            
            updateNumber += 1
            Thread.sleep(forTimeInterval: 0.5)
        }
    } catch {
        print("Publisher error: \(error)")
    }
}

func runSubscriber(_ topic: String, _ id: Int) {
    do {
        let context = Context()
        
        // Create a SUB socket
        let subscriber = try context.connect(type: .sub, url: "tcp://localhost:5556")
        
        // Set high water mark for incoming messages
        try subscriber.setReceiveHighWaterMark(1000)
        
        // Subscribe to the specified topic
        if topic.isEmpty {
            // Subscribe to all messages
            try subscriber.subscribe(prefix: "")
            print("Subscriber \(id) subscribed to all topics")
        } else {
            try subscriber.subscribe(prefix: topic)
            print("Subscriber \(id) subscribed to topic: \(topic)")
        }
        
        // Set receive timeout
        try subscriber.setReceiveTimeout(milliseconds: 5000)
        
        print("Subscriber \(id) started, waiting for updates...")
        
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

// For demo purposes, run the publisher in a separate thread
DispatchQueue.global().async {
    runPublisher()
}

// Wait a moment for the publisher to start
Thread.sleep(forTimeInterval: 1.0)

// Create three subscribers with different subscription patterns
DispatchQueue.global().async {
    runSubscriber("sports", 1) // Only receive sports updates
}

DispatchQueue.global().async {
    runSubscriber("weather", 2) // Only receive weather updates
}

DispatchQueue.global().async {
    runSubscriber("", 3) // Receive all updates
}

// Wait for all to complete
Thread.sleep(forTimeInterval: 15.0)
print("Example completed")