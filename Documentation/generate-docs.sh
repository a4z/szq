#!/bin/bash

# Script to generate documentation for szq library
# This script creates a docs directory and copies all documentation there

# Create docs directory
mkdir -p docs
mkdir -p docs/examples

# Copy main documentation files
cp README.md docs/
cp basic-patterns.md docs/
cp socket-types.md docs/
cp advanced-features.md docs/
cp api-reference.md docs/

# Copy examples
cp examples/*.swift docs/examples/

# Create index.html for GitHub Pages if needed
cat > docs/index.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>szq - Swift ZeroMQ Library</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        code {
            background-color: #f4f4f4;
            padding: 2px 4px;
            border-radius: 4px;
        }
        pre {
            background-color: #f4f4f4;
            padding: 16px;
            border-radius: 8px;
            overflow-x: auto;
        }
        a {
            color: #0066cc;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .nav {
            background-color: #f8f8f8;
            padding: 10px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .nav a {
            margin-right: 15px;
        }
    </style>
</head>
<body>
    <div class="nav">
        <a href="index.html">Home</a>
        <a href="basic-patterns.html">Basic Patterns</a>
        <a href="socket-types.html">Socket Types</a>
        <a href="advanced-features.html">Advanced Features</a>
        <a href="api-reference.html">API Reference</a>
        <a href="https://github.com/yourusername/szq">GitHub</a>
    </div>

    <h1>szq - Swift ZeroMQ Library</h1>
    
    <p>
        szq is a comprehensive Swift wrapper for the ZeroMQ messaging library, providing
        an elegant and type-safe Swift API for all ZeroMQ functionality.
    </p>
    
    <p>
        <a href="README.html">Full Documentation</a>
    </p>
    
    <h2>Quick Start</h2>
    
    <h3>Installation</h3>
    
    <pre><code>// In Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/szq.git", from: "1.0.0")
]</code></pre>
    
    <h3>Basic Example</h3>
    
    <pre><code>import szq

let context = Context()

// Create a REP socket (server)
let server = try context.bind(type: .rep, url: "tcp://*:5555")

// Create a REQ socket (client)
let client = try context.connect(type: .req, url: "tcp://localhost:5555")

// Client sends a request
try client.send(Message(string: "Hello"))

// Server receives the request
if let messages = try server.recvAll(), let requestString = messages[0].string {
    print("Received: \(requestString)")
    
    // Server sends a reply
    try server.send(Message(string: "World"))
    
    // Client receives the reply
    if let reply = try client.recvAll(), let replyString = reply[0].string {
        print("Received: \(replyString)")
    }
}</code></pre>
    
    <h2>Documentation</h2>
    
    <ul>
        <li><a href="README.html">Overview</a></li>
        <li><a href="basic-patterns.html">Basic Patterns</a></li>
        <li><a href="socket-types.html">Socket Types</a></li>
        <li><a href="advanced-features.html">Advanced Features</a></li>
        <li><a href="api-reference.html">API Reference</a></li>
    </ul>
    
    <h2>Examples</h2>
    
    <ul>
        <li><a href="examples/request-reply.swift">Request-Reply Pattern</a></li>
        <li><a href="examples/publish-subscribe.swift">Publish-Subscribe Pattern</a></li>
        <li><a href="examples/dealer-router.swift">Dealer-Router Pattern</a></li>
        <li><a href="examples/secure-pub-sub.swift">Secure Publish-Subscribe</a></li>
        <li><a href="examples/proxy-example.swift">Proxy Patterns</a></li>
        <li><a href="examples/socket-options.swift">Socket Options</a></li>
    </ul>
</body>
</html>
EOL

# Convert markdown files to HTML if the markdown command is available
if command -v markdown > /dev/null; then
    for file in docs/*.md; do
        markdown "$file" > "${file%.md}.html"
    done
    echo "Markdown files converted to HTML"
else
    echo "markdown command not found, skipping HTML conversion"
fi

echo "Documentation generated in the docs directory"