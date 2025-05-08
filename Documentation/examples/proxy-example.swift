// Proxy Pattern Example
// This demonstrates using a proxy to create an intermediary between frontend and backend

import szq
import Foundation

// In a real application, each component would run in a separate process

// 1. Queue Proxy Example (ROUTER-DEALER)

func runQueueProxyExample() {
    do {
        let context = Context()
        
        print("Starting Queue Proxy (ROUTER-DEALER)...")
        
        // Create a queue proxy (ROUTER-DEALER)
        let queueProxy = try ProxyPattern.queue.createProxy(
            context: context,
            frontendUrl: "tcp://*:5570",
            backendUrl: "tcp://*:5571"
        )
        
        // Start the proxy in a separate thread
        try queueProxy.start()
        
        print("Queue proxy started")
        
        // Client function (would be in a separate process)
        func runClient(id: Int) {
            do {
                let clientContext = Context()
                let client = try clientContext.connect(type: .req, url: "tcp://localhost:5570")
                
                for i in 1...5 {
                    let requestText = "Request \(i) from Client \(id)"
                    try client.send(Message(string: requestText))
                    print("Client \(id) sent: \(requestText)")
                    
                    if let reply = try client.recvAll(), let replyText = reply[0].string {
                        print("Client \(id) received: \(replyText)")
                    }
                    
                    Thread.sleep(forTimeInterval: 0.1)
                }
            } catch {
                print("Client \(id) error: \(error)")
            }
        }
        
        // Worker function (would be in a separate process)
        func runWorker(id: Int) {
            do {
                let workerContext = Context()
                let worker = try workerContext.connect(type: .rep, url: "tcp://localhost:5571")
                
                var requestsHandled = 0
                
                while requestsHandled < 10 {
                    if let request = try worker.recvAll(), let requestText = request[0].string {
                        print("Worker \(id) received: \(requestText)")
                        
                        // Simulate work
                        Thread.sleep(forTimeInterval: 0.1)
                        
                        try worker.send(Message(string: "Response to \(requestText) from Worker \(id)"))
                        requestsHandled += 1
                    }
                }
            } catch {
                print("Worker \(id) error: \(error)")
            }
        }
        
        // Start workers
        for i in 1...3 {
            DispatchQueue.global().async {
                runWorker(id: i)
            }
        }
        
        // Start clients after workers connect
        Thread.sleep(forTimeInterval: 1.0)
        
        for i in 1...2 {
            DispatchQueue.global().async {
                runClient(id: i)
            }
        }
        
        // Let the proxy run for a while
        Thread.sleep(forTimeInterval: 10.0)
        
        // Stop the proxy
        try queueProxy.stop()
        print("Queue proxy stopped")
        
    } catch {
        print("Queue proxy error: \(error)")
    }
}

// 2. Forwarder Proxy Example (SUB-PUB)

func runForwarderProxyExample() {
    do {
        let context = Context()
        
        print("\nStarting Forwarder Proxy (SUB-PUB)...")
        
        // Create a forwarder proxy (SUB-PUB)
        let forwarderProxy = try ProxyPattern.forwarder.createProxy(
            context: context,
            frontendUrl: "tcp://*:5572",
            backendUrl: "tcp://*:5573"
        )
        
        // Start the proxy in a separate thread
        try forwarderProxy.start()
        
        print("Forwarder proxy started")
        
        // Publisher function (would be in a separate process)
        func runPublisher(id: Int) {
            do {
                let pubContext = Context()
                let publisher = try pubContext.connect(type: .pub, url: "tcp://localhost:5572")
                
                for i in 1...10 {
                    let topic = ["sports", "weather", "news"][i % 3]
                    let message = "\(topic) update \(i) from Publisher \(id)"
                    try publisher.send(Message(string: message))
                    print("Publisher \(id) sent: \(message)")
                    
                    Thread.sleep(forTimeInterval: 0.2)
                }
            } catch {
                print("Publisher \(id) error: \(error)")
            }
        }
        
        // Subscriber function (would be in a separate process)
        func runSubscriber(id: Int, topic: String) {
            do {
                let subContext = Context()
                let subscriber = try subContext.connect(type: .sub, url: "tcp://localhost:5573")
                
                // Subscribe to the specified topic
                try subscriber.subscribe(prefix: topic)
                print("Subscriber \(id) subscribed to: \(topic)")
                
                // Set receive timeout
                try subscriber.setReceiveTimeout(milliseconds: 5000)
                
                var messagesReceived = 0
                
                while messagesReceived < 10 {
                    if let message = try subscriber.recv(), let messageText = message.string {
                        print("Subscriber \(id) received: \(messageText)")
                        messagesReceived += 1
                    } else {
                        // Timeout
                        break
                    }
                }
            } catch {
                print("Subscriber \(id) error: \(error)")
            }
        }
        
        // Start subscribers
        let topics = ["sports", "weather", "news", ""]  // Empty string subscribes to all
        
        for (i, topic) in topics.enumerated() {
            DispatchQueue.global().async {
                runSubscriber(id: i + 1, topic: topic)
            }
        }
        
        // Start publishers after subscribers connect
        Thread.sleep(forTimeInterval: 1.0)
        
        for i in 1...2 {
            DispatchQueue.global().async {
                runPublisher(id: i)
            }
        }
        
        // Let the proxy run for a while
        Thread.sleep(forTimeInterval: 10.0)
        
        // Stop the proxy
        try forwarderProxy.stop()
        print("Forwarder proxy stopped")
        
    } catch {
        print("Forwarder proxy error: \(error)")
    }
}

// 3. Streamer Proxy Example (PULL-PUSH)

func runStreamerProxyExample() {
    do {
        let context = Context()
        
        print("\nStarting Streamer Proxy (PULL-PUSH)...")
        
        // Create a streamer proxy (PULL-PUSH)
        let streamerProxy = try ProxyPattern.streamer.createProxy(
            context: context,
            frontendUrl: "tcp://*:5574",
            backendUrl: "tcp://*:5575"
        )
        
        // Start the proxy in a separate thread
        try streamerProxy.start()
        
        print("Streamer proxy started")
        
        // Producer function (would be in a separate process)
        func runProducer(id: Int) {
            do {
                let prodContext = Context()
                let producer = try prodContext.connect(type: .push, url: "tcp://localhost:5574")
                
                for i in 1...10 {
                    let message = "Task \(i) from Producer \(id)"
                    try producer.send(Message(string: message))
                    print("Producer \(id) sent: \(message)")
                    
                    Thread.sleep(forTimeInterval: 0.1)
                }
            } catch {
                print("Producer \(id) error: \(error)")
            }
        }
        
        // Consumer function (would be in a separate process)
        func runConsumer(id: Int) {
            do {
                let consContext = Context()
                let consumer = try consContext.connect(type: .pull, url: "tcp://localhost:5575")
                
                // Set receive timeout
                try consumer.setReceiveTimeout(milliseconds: 5000)
                
                var tasksProcessed = 0
                
                while tasksProcessed < 10 {
                    if let task = try consumer.recv(), let taskText = task.string {
                        print("Consumer \(id) received: \(taskText)")
                        
                        // Simulate processing
                        Thread.sleep(forTimeInterval: 0.2)
                        
                        tasksProcessed += 1
                    } else {
                        // Timeout
                        break
                    }
                }
            } catch {
                print("Consumer \(id) error: \(error)")
            }
        }
        
        // Start consumers
        for i in 1...3 {
            DispatchQueue.global().async {
                runConsumer(id: i)
            }
        }
        
        // Start producers after consumers connect
        Thread.sleep(forTimeInterval: 1.0)
        
        for i in 1...2 {
            DispatchQueue.global().async {
                runProducer(id: i)
            }
        }
        
        // Let the proxy run for a while
        Thread.sleep(forTimeInterval: 10.0)
        
        // Stop the proxy
        try streamerProxy.stop()
        print("Streamer proxy stopped")
        
    } catch {
        print("Streamer proxy error: \(error)")
    }
}

// Run all three proxy examples
print("ZeroMQ Proxy Examples\n")
print("=====================")

runQueueProxyExample()
runForwarderProxyExample()
runStreamerProxyExample()

print("\nAll proxy examples completed")