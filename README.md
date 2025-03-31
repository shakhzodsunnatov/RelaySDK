# RelaySDK

A Swift package providing a robust, easy-to-use interface for NATS messaging services.

## Features

- 🚀 Simple and intuitive API for NATS messaging
- 🔒 Thread-safe operations
- 📡 Reliable connection handling
- 📦 Queue management
- 📝 Message history support
- 🔍 Detailed logging
- ⚡️ Async/await support
- 🛡️ Error handling

## Requirements

- iOS 12.0+ / macOS 10.15+
- Swift 5.0+
- Xcode 13.0+

## Installation

### Swift Package Manager

Add RelaySDK to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/RelaySDK.git", from: "1.0.0")
]
```

## Quick Start

```swift
import RelaySDK

// Configure
let config = RelayManager.Configuration(
    natsURL: "nats://your-server:4222",
    apiBaseURL: "https://api.your-server.com",
    apiKey: "your-api-key"
)

// Initialize
RelayManager.shared.configure(with: config)

// Connect
RelayManager.shared.connect { error in
    if let error = error {
        print("Connection failed: \(error)")
        return
    }
    print("Connected successfully!")
}

// Subscribe
let subscription = RelayManager.shared.subscribe(to: "greetings") { message in
    print("Received: \(message.payload ?? "")")
}

// Publish
RelayManager.shared.publish("Hello, World!", to: "greetings") { error in
    if let error = error {
        print("Failed to publish: \(error)")
        return
    }
    print("Published successfully!")
}
```

## Detailed Usage

### Connection Management

```swift
// Connect with custom configuration
let config = RelayManager.Configuration(
    natsURL: "nats://your-server:4222",
    apiBaseURL: "https://api.your-server.com",
    apiKey: "your-api-key",
    natsConfig: NatsClientConfig(
        verbose: true,
        pedantic: false,
        name: "MyApp"
    )
)

// Disconnect when done
RelayManager.shared.disconnect()
```

### Message Publishing

```swift
// Simple publish
RelayManager.shared.publish("Hello!", to: "greetings") { error in
    // Handle result
}

// Publish with queue
RelayManager.shared.publish("Task data", to: "tasks.queue") { error in
    // Handle result
}
```

### Message Subscription

```swift
// Basic subscription
let sub = RelayManager.shared.subscribe(to: "updates") { message in
    // Handle message
}

// Queue group subscription
let queueSub = RelayManager.shared.subscribe(
    to: "tasks",
    queue: "workers"
) { message in
    // Handle task
}

// Unsubscribe
RelayManager.shared.unsubscribe(from: sub)
```

### Message History

```swift
RelayManager.shared.getHistory(
    for: "updates",
    startTime: Date().addingTimeInterval(-3600), // Last hour
    endTime: Date(),
    limit: 100
) { result in
    switch result {
    case .success(let messages):
        // Handle messages
    case .failure(let error):
        // Handle error
    }
}
```

## Error Handling

The SDK provides detailed error types:

```swift
public enum RelayError: Error {
    case notConfigured
    case invalidResponse
    case networkError(Error)
    case apiError(String)
}
```

## Logging

Configure logging level:

```swift
let config = RelayManager.Configuration(
    // ... other config ...
    loglevel: .debug
)
```

## Best Practices

1. **Connection Management**
   - Maintain a single shared instance of RelayManager
   - Handle connection errors appropriately
   - Implement reconnection logic for production apps

2. **Message Handling**
   - Use queue groups for load balancing
   - Implement timeout handling for requests
   - Handle messages asynchronously when appropriate

3. **Error Handling**
   - Always check for errors in completion handlers
   - Implement proper error recovery
   - Log errors for debugging

4. **Resource Management**
   - Store subscription references
   - Unsubscribe when subscriptions are no longer needed
   - Close connections when done

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

RelaySDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Support

For support, please:
- Check our [Documentation](docs/)
- Open an [Issue](issues/new)
- Contact us at support@relaysdk.com

## Authors

Your Name - [@yourusername](https://github.com/shakhzodsunnatov)

## Acknowledgments

- [NATS.io](https://nats.io) - The underlying messaging system
- [Swift-NIO](https://github.com/apple/swift-nio) - Networking foundation
- [Swift-Log](https://github.com/apple/swift-log) - Logging system

---

Made with ❤️ by Relay
