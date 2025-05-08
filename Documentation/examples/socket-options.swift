// Socket Options Examples
// This file demonstrates how to use various ZeroMQ socket options with szq

import szq
import Foundation

// Function to demonstrate high water mark options
func demonstrateHighWaterMarkOptions() {
    print("\n=== High Water Mark Options ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .push, url: "inproc://hwm-test")
        
        // Set send high water mark (default: 1000)
        try socket.setSendHighWaterMark(2000)
        let sendHwm = try socket.getSendHighWaterMark()
        print("Send high water mark: \(sendHwm)")
        
        // Set receive high water mark
        try socket.setReceiveHighWaterMark(5000)
        let recvHwm = try socket.getReceiveHighWaterMark()
        print("Receive high water mark: \(recvHwm)")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate timeout options
func demonstrateTimeoutOptions() {
    print("\n=== Timeout Options ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .req, url: "inproc://timeout-test")
        
        // Set send timeout (in milliseconds)
        try socket.setSendTimeout(milliseconds: 1000) // 1 second
        let sendTimeout = try socket.getSendTimeout()
        print("Send timeout: \(sendTimeout)ms")
        
        // Set receive timeout
        try socket.setReceiveTimeout(milliseconds: 2000) // 2 seconds
        let recvTimeout = try socket.getReceiveTimeout()
        print("Receive timeout: \(recvTimeout)ms")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate reconnection options
func demonstrateReconnectionOptions() {
    print("\n=== Reconnection Options ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .dealer, url: "inproc://reconnect-test")
        
        // Set reconnection interval (default: 100ms)
        try socket.setReconnectInterval(milliseconds: 200)
        let reconnectInterval = try socket.getReconnectInterval()
        print("Reconnect interval: \(reconnectInterval)ms")
        
        // Set maximum reconnection interval (for exponential backoff)
        try socket.setMaxReconnectInterval(milliseconds: 10000) // 10 seconds
        let maxReconnectInterval = try socket.getMaxReconnectInterval()
        print("Max reconnect interval: \(maxReconnectInterval)ms")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate TCP options
func demonstrateTCPOptions() {
    print("\n=== TCP Options ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .req, url: "inproc://tcp-test")
        
        // Enable TCP keepalive
        try socket.setTCPKeepAlive(1)
        let keepAlive = try socket.getTCPKeepAlive()
        print("TCP Keepalive: \(keepAlive)")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate IP Version options
func demonstrateIPVersionOptions() {
    print("\n=== IP Version Options ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .req, url: "inproc://ip-test")
        
        // Enable IPv6 support
        try socket.setIPv6(1)
        let ipv6Enabled = try socket.getIPv6()
        print("IPv6 enabled: \(ipv6Enabled)")
        
        // Alternatively, restrict to IPv4 only
        try socket.setIPv4Only(1)
        let ipv4Only = try socket.getIPv4Only()
        print("IPv4 only: \(ipv4Only)")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate connection options
func demonstrateConnectionOptions() {
    print("\n=== Connection Options ===")
    
    do {
        let context = Context()
        
        // Bind a socket to an address
        let socket = try context.bind(type: .rep, url: "tcp://*:5585")
        
        // Get the last endpoint bound/connected to
        let lastEndpoint = try socket.getLastEndpoint()
        print("Last endpoint: \(lastEndpoint)")
        
        // Set handshake interval timeout (default: 30000ms)
        try socket.setHandshakeInterval(milliseconds: 5000) // 5 seconds
        let handshakeInterval = try socket.getHandshakeInterval()
        print("Handshake interval: \(handshakeInterval)ms")
        
        // Set immediate mode (don't queue messages when no connection)
        try socket.setImmediate(1)
        let immediate = try socket.getImmediate()
        print("Immediate mode: \(immediate)")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate socket information
func demonstrateSocketInformation() {
    print("\n=== Socket Information ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .dealer, url: "inproc://info-test")
        
        // Get the socket type
        let socketType = try socket.getType()
        print("Socket type: \(socketType)")
        
        // Check for events (ZMQ_POLLIN, ZMQ_POLLOUT)
        let events = try socket.getEvents()
        let canRead = events & ZMQ_POLLIN != 0
        let canWrite = events & ZMQ_POLLOUT != 0
        print("Can read: \(canRead), Can write: \(canWrite)")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate multicast options
func demonstrateMulticastOptions() {
    print("\n=== Multicast Options ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .pub, url: "inproc://multicast-test")
        
        // Set multicast hops (default: 1)
        try socket.setMulticastHops(5)
        let hops = try socket.getMulticastHops()
        print("Multicast hops: \(hops)")
        
        // Set multicast data rate (kilobits per second)
        try socket.setMulticastRate(1000) // 1 Mbps
        let rate = try socket.getMulticastRate()
        print("Multicast rate: \(rate) Kbps")
        
        // Set multicast recovery interval
        try socket.setMulticastRecoveryInterval(milliseconds: 10000) // 10 seconds
        let recoveryInterval = try socket.getMulticastRecoveryInterval()
        print("Multicast recovery interval: \(recoveryInterval)ms")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate message size options
func demonstrateMessageSizeOptions() {
    print("\n=== Message Size Options ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .dealer, url: "inproc://msgsize-test")
        
        // Set maximum message size (bytes, default: no limit)
        try socket.setMaxMessageSize(1_000_000) // ~1 MB
        let maxSize = try socket.getMaxMessageSize()
        print("Maximum message size: \(maxSize) bytes")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate ROUTER/DEALER socket options
func demonstrateRouterDealerOptions() {
    print("\n=== ROUTER/DEALER Socket Options ===")
    
    do {
        let context = Context()
        
        // ROUTER socket options
        let router = try context.connect(type: .router, url: "inproc://router-test")
        
        // Set ROUTER mandatory (don't drop unroutable messages)
        try router.setRouterMandatory(1)
        print("Router mandatory set to 1")
        
        // Set ROUTER handover for peer identities
        try router.setRouterHandover(1)
        print("Router handover set to 1")
        
        // Set ROUTER raw (use raw identities)
        try router.setRouterRaw(1)
        print("Router raw set to 1")
        
        // DEALER socket options (identity setting)
        let dealer = try context.connect(type: .dealer, url: "inproc://dealer-test")
        
        // Set dealer identity
        try dealer.setIdentity("dealer-1")
        
        // Get the identity
        let identity = try dealer.getIdentity()
        if let identityStr = identity.string {
            print("Dealer identity: \(identityStr)")
        } else {
            print("Dealer identity size: \(identity.size) bytes")
        }
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate PUB/SUB socket options
func demonstratePubSubOptions() {
    print("\n=== PUB/SUB Socket Options ===")
    
    do {
        let context = Context()
        
        // PUB socket options
        let publisher = try context.connect(type: .pub, url: "inproc://pub-test")
        
        // Set conflate option (only keep most recent message)
        try publisher.setConflate(1)
        let conflate = try publisher.getConflate()
        print("Conflate option: \(conflate)")
        
        // SUB socket options
        let subscriber = try context.connect(type: .sub, url: "inproc://sub-test")
        
        // Subscribe to topics
        try subscriber.subscribe(prefix: "topic1")
        print("Subscribed to 'topic1'")
        
        try subscriber.subscribe(prefix: "topic2")
        print("Subscribed to 'topic2'")
        
        // Unsubscribe from a topic
        try subscriber.unsubscribe(prefix: "topic1")
        print("Unsubscribed from 'topic1'")
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate proxy settings
func demonstrateProxySettings() {
    print("\n=== Proxy Settings ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .req, url: "inproc://proxy-test")
        
        // Set SOCKS5 proxy address
        try socket.setProxy("tcp://proxy.example.com:1080")
        
        // Set SOCKS5 authentication
        try socket.setSocks5Username("username")
        try socket.setSocks5Password("password")
        
        // Get current proxy address
        if let proxyAddress = try socket.getProxy() {
            print("Using proxy: \(proxyAddress)")
        } else {
            print("No proxy configured")
        }
    } catch {
        print("Error: \(error)")
    }
}

// Function to demonstrate thread affinity
func demonstrateThreadAffinity() {
    print("\n=== Thread Affinity ===")
    
    do {
        let context = Context()
        let socket = try context.connect(type: .req, url: "inproc://affinity-test")
        
        // Set thread affinity (bitmask, default: all threads)
        try socket.setAffinity(1) // Only use thread 0
        let affinity = try socket.getAffinity()
        print("Thread affinity: \(affinity)")
    } catch {
        print("Error: \(error)")
    }
}

// Main function to demonstrate all socket options
func demonstrateAllSocketOptions() {
    print("ZeroMQ Socket Options Examples")
    print("==============================")
    
    demonstrateHighWaterMarkOptions()
    demonstrateTimeoutOptions()
    demonstrateReconnectionOptions()
    demonstrateTCPOptions()
    demonstrateIPVersionOptions()
    demonstrateConnectionOptions()
    demonstrateSocketInformation()
    demonstrateMulticastOptions()
    demonstrateMessageSizeOptions()
    demonstrateRouterDealerOptions()
    demonstratePubSubOptions()
    demonstrateProxySettings()
    demonstrateThreadAffinity()
    
    print("\nAll socket options examples completed")
}

// Run the demonstration
demonstrateAllSocketOptions()