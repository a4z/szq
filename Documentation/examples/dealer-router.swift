// Dealer-Router Advanced Pattern Example
// This demonstrates asynchronous request-reply messaging with worker load balancing

import szq
import Foundation

// In a real application, you would run these components in separate processes

// Worker Function - Multiple instances will handle requests
func runWorker(id: String) {
    do {
        let context = Context()
        
        // Create a DEALER socket
        let worker = try context.connect(type: .dealer, url: "tcp://localhost:5560")
        
        // Set worker identity
        try worker.setIdentity(id)
        
        // Set reconnection parameters
        try worker.setReconnectInterval(milliseconds: 100)
        try worker.setMaxReconnectInterval(milliseconds: 10000)
        
        print("Worker \(id) started")
        
        var requestsHandled = 0
        
        while requestsHandled < 10 { // Handle 10 requests then exit
            // Receive a client request (via the broker)
            guard let frames = try worker.recvAll(), frames.count >= 3 else {
                Thread.sleep(forTimeInterval: 0.1)
                continue
            }
            
            // Frame 0: Client identity (router)
            // Frame 1: Empty delimiter
            // Frame 2: Request content
            let clientID = frames[0]
            let request = frames[2]
            
            if let requestText = request.string {
                print("Worker \(id) received request: \(requestText)")
                
                // Simulate work time based on worker ID
                let workTime = Double(Int(id) ?? 1) * 0.1
                Thread.sleep(forTimeInterval: workTime)
                
                // Send reply back to client (through router)
                // Frame 0: Client identity (router from original request)
                // Frame 1: Empty delimiter
                // Frame 2: Reply content
                try worker.send(clientID, Message(), Message(string: "Response from Worker \(id) to request: \(requestText)"))
                
                requestsHandled += 1
                print("Worker \(id) handled request \(requestsHandled)/10")
            }
        }
        
        print("Worker \(id) completed all requests")
        
    } catch {
        print("Worker \(id) error: \(error)")
    }
}

// Router/Broker Function - Distributes requests to workers
func runBroker() {
    do {
        let context = Context()
        
        // Frontend socket (ROUTER) - faces clients
        let frontend = try context.bind(type: .router, url: "tcp://*:5559")
        
        // Backend socket (ROUTER) - faces workers
        let backend = try context.bind(type: .router, url: "tcp://*:5560")
        
        // Configure router socket
        try frontend.setRouterMandatory(1) // Report errors on unroutable messages
        try frontend.setRouterHandover(1) // Allow handover of client connections
        
        print("Broker started")
        
        // Use polling to monitor both sockets
        var items = [zmq_pollitem_t](repeating: zmq_pollitem_t(), count: 2)
        
        // Setup frontend poll item
        items[0].socket = frontend.socket
        items[0].events = Int16(ZMQ_POLLIN)
        
        // Setup backend poll item
        items[1].socket = backend.socket
        items[1].events = Int16(ZMQ_POLLIN)
        
        // Set up worker queue (for LRU routing)
        var workerQueue: [Data] = []
        
        var messageCount = 0
        let maxMessages = 50 // Handle 50 total messages then exit
        
        while messageCount < maxMessages {
            // Poll for activity with 1 second timeout
            let rc = zmq_poll(&items, 2, 1000)
            if rc == -1 {
                print("Poll error")
                break
            }
            
            // Process messages from the frontend (clients)
            if items[0].revents & Int16(ZMQ_POLLIN) != 0 {
                if let frames = try frontend.recvAll() {
                    if workerQueue.isEmpty {
                        // No workers available, either queue the message or drop it
                        print("No workers available, request queued")
                    } else {
                        // Route message to next worker
                        let workerID = workerQueue.removeFirst()
                        
                        // Convert worker ID to a message
                        let workerIdentity = try Message(size: workerID.count)
                        if let dataPtr = workerIdentity.data {
                            workerID.copyBytes(to: dataPtr.bindMemory(to: UInt8.self, capacity: workerID.count), count: workerID.count)
                        }
                        
                        // Forward message to worker
                        // Frame 0: Worker identity
                        // Frame 1+: Original client frames
                        try backend.send(workerIdentity)
                        
                        for frame in frames {
                            try backend.send(frame)
                        }
                        
                        messageCount += 1
                        print("Broker routed request \(messageCount)/\(maxMessages) to worker")
                    }
                }
            }
            
            // Process messages from the backend (workers)
            if items[1].revents & Int16(ZMQ_POLLIN) != 0 {
                if let frames = try backend.recvAll(), frames.count >= 1 {
                    // First frame is worker identity
                    let workerIdentity = frames[0]
                    
                    // Add worker to queue
                    var workerID = Data(count: workerIdentity.size)
                    if let dataPtr = workerIdentity.data {
                        workerID.withUnsafeMutableBytes { buffer in
                            memcpy(buffer.baseAddress, dataPtr, workerIdentity.size)
                        }
                    }
                    
                    workerQueue.append(workerID)
                    print("Worker added to queue, queue size: \(workerQueue.count)")
                    
                    if frames.count >= 3 {
                        // This is a response to a client
                        // Forward frames to client
                        // Frame 1: Client identity
                        // Frame 2: Empty delimiter
                        // Frame 3+: Reply content
                        
                        let clientFrames = Array(frames.dropFirst())
                        for (index, frame) in clientFrames.enumerated() {
                            let isLast = index == clientFrames.count - 1
                            if isLast {
                                try frontend.send(frame)
                            } else {
                                try frontend.send(frame, dontwait: false)
                            }
                        }
                        
                        print("Broker routed response back to client")
                    }
                }
            }
        }
        
        print("Broker completed all message routing")
        
    } catch {
        print("Broker error: \(error)")
    }
}

// Client Function - Sends requests and receives replies
func runClient(id: String) {
    do {
        let context = Context()
        
        // Create a DEALER socket
        let client = try context.connect(type: .dealer, url: "tcp://localhost:5559")
        
        // Set client identity
        try client.setIdentity("Client-\(id)")
        
        print("Client \(id) started")
        
        for i in 1...10 {
            // Compose and send request
            let requestText = "Request \(i) from Client \(id)"
            
            // Send request (empty frame + content)
            try client.send(Message(), Message(string: requestText))
            print("Client \(id) sent request \(i)")
            
            // Wait for reply
            let reply = try client.recvAll()
            if let frames = reply, frames.count >= 2 {
                // First frame is empty, second is the reply content
                if let replyText = frames[1].string {
                    print("Client \(id) received reply to request \(i): \(replyText)")
                }
            } else {
                print("Client \(id) received no reply to request \(i)")
            }
            
            // Wait between requests
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        print("Client \(id) finished all requests")
        
    } catch {
        print("Client \(id) error: \(error)")
    }
}

// Start the broker
DispatchQueue.global().async {
    runBroker()
}

// Wait for broker to start
Thread.sleep(forTimeInterval: 1.0)

// Start multiple workers
for i in 1...3 {
    DispatchQueue.global().async {
        runWorker(id: "\(i)")
    }
}

// Wait for workers to connect
Thread.sleep(forTimeInterval: 1.0)

// Start multiple clients
for i in 1...2 {
    DispatchQueue.global().async {
        runClient(id: "\(i)")
    }
}

// Wait for everything to complete
Thread.sleep(forTimeInterval: 30.0)
print("Example completed")