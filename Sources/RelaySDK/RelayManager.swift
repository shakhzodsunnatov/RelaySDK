//
//  RelayManager.swift
//  RelaySDK
//
//  Created by Shaxzod on 31/03/25.
//


import Foundation

/// RelayManager is the main entry point for the RelaySDK.
/// It provides a simple interface for pub/sub messaging, queue management, and history retrieval.
public final class RelayManager {
    
    // MARK: - Types
    
    /// Configuration for the RelayManager
    public struct Configuration {
        /// The NATS server URL
        public let natsURL: String
        /// The REST API base URL
        public let apiBaseURL: String
        /// The API key for authentication
        public let apiKey: String
        /// Optional configuration for the NATS client
        public var natsConfig: NatsClientConfig
        
        public init(
            natsURL: String,
            apiBaseURL: String,
            apiKey: String,
            natsConfig: NatsClientConfig = NatsClientConfig()
        ) {
            self.natsURL = natsURL
            self.apiBaseURL = apiBaseURL
            self.apiKey = apiKey
            self.natsConfig = natsConfig
        }
    }
    
    /// Completion handler type for async operations
    public typealias CompletionHandler<T> = (Result<T, Error>) -> Void
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    @MainActor public static let shared = RelayManager()
    
    /// The current configuration
    private var configuration: Configuration?
    
    /// The NATS client instance
    private var natsClient: NatsClient?
    
    /// The API client instance
    private var apiClient: RelayAPIClient?
    
    /// Queue for managing async operations
    private let queue = DispatchQueue(label: "com.relaysdk.manager")
    
    /// Logger instance
    private let logger = LoggerManager.shared.logger
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configure the RelayManager with the provided settings
    /// - Parameter config: The configuration to use
    public func configure(with config: Configuration) {
        queue.sync {
            self.configuration = config
            self.natsClient = NatsClient(config.natsURL, config.natsConfig)
            self.apiClient = RelayAPIClient(baseURL: config.apiBaseURL, apiKey: config.apiKey)
        }
    }
    
    // MARK: - Connection Management
    
    /// Connect to the Relay service
    /// - Parameter completion: Called when the connection is established or fails
    public func connect(completion: @escaping (Error?) -> Void) {
        queue.async {
            guard let client = self.natsClient else {
                completion(RelayError.notConfigured)
                return
            }
            
            do {
                try client.connect()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    /// Disconnect from the Relay service
    public func disconnect() {
        queue.async {
            self.natsClient?.disconnect()
        }
    }
    
    // MARK: - Pub/Sub Methods
    
    /// Subscribe to a subject
    /// - Parameters:
    ///   - subject: The subject to subscribe to
    ///   - queue: Optional queue group name
    ///   - handler: Callback for received messages
    /// - Returns: A subscription object that can be used to unsubscribe
    @discardableResult
    public func subscribe(
        to subject: String,
        queue: String? = nil,
        handler: @escaping (NatsMessage) -> Void
    ) -> NatsSubject {
        if let queue = queue {
            return natsClient?.subscribe(to: subject, asPartOf: queue, handler) ?? NatsSubject(subject: subject)
        } else {
            return natsClient?.subscribe(to: subject, handler) ?? NatsSubject(subject: subject)
        }
    }
    
    /// Publish a message to a subject
    /// - Parameters:
    ///   - message: The message to publish
    ///   - subject: The subject to publish to
    ///   - completion: Called when the publish succeeds or fails
    public func publish(
        _ message: String,
        to subject: String,
        completion: @escaping (Error?) -> Void
    ) {
        queue.async {
            do {
                try self.natsClient?.publishSync(message, to: subject)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    /// Unsubscribe from a subject
    /// - Parameter subscription: The subscription to cancel
    public func unsubscribe(from subscription: NatsSubject) {
        queue.async {
            self.natsClient?.unsubscribe(from: subscription)
        }
    }
    
    // MARK: - Queue Management (REST API)
    
    /// Create a new queue
    /// - Parameters:
    ///   - name: The name of the queue
    ///   - completion: Called with the created queue or error
    public func createQueue(name: String, completion: @escaping CompletionHandler<QueueInfo>) {
        guard let apiClient = apiClient else {
            completion(.failure(RelayError.notConfigured))
            return
        }
        
        apiClient.createQueue(name, completion: completion)
    }
    
    /// Get queue information
    /// - Parameters:
    ///   - queueName: The name of the queue
    ///   - completion: Called with the queue info or error
    public func getQueueInfo(queueName: String, completion: @escaping CompletionHandler<QueueInfo>) {
        guard let apiClient = apiClient else {
            completion(.failure(RelayError.notConfigured))
            return
        }
        
        apiClient.getQueueInfo(queueName, completion: completion)
    }
    
    // MARK: - History API (REST)
    
    /// Retrieve message history for a subject
    /// - Parameters:
    ///   - subject: The subject to get history for
    ///   - startTime: Optional start time filter
    ///   - endTime: Optional end time filter
    ///   - limit: Maximum number of messages to retrieve
    ///   - completion: Called with the messages or error
    public func getHistory(
        for subject: String,
        startTime: Date? = nil,
        endTime: Date? = nil,
        limit: Int = 100,
        completion: @escaping CompletionHandler<[HistoryMessage]>
    ) {
        guard let apiClient = apiClient else {
            completion(.failure(RelayError.notConfigured))
            return
        }
        
        apiClient.getHistory(
            subject: subject,
            startTime: startTime,
            endTime: endTime,
            limit: limit,
            completion: completion
        )
    }
}

// MARK: - Supporting Types

/// Represents information about a queue
public struct QueueInfo: Codable {
    public let name: String
    public let messageCount: Int
    public let consumerCount: Int
    public let createdAt: Date
}

/// Represents a historical message
public struct HistoryMessage: Codable {
    public let subject: String
    public let data: String
    public let timestamp: Date
    public let sequence: UInt64
}

/// Custom errors for the RelaySDK
public enum RelayError: Error {
    case notConfigured
    case invalidResponse
    case networkError(Error)
    case apiError(String)
} 
