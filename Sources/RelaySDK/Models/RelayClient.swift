//
//  File.swift
//  RelaySDK
//
//  Created by Shaxzod on 31/03/25.
//

//import Foundation
//import Nats
//
//public protocol RelayClientDelegate: AnyObject {
//    func relayClient(_ client: RelayClient, didChangeConnectionStatus status: RelayClient.ConnectionStatus)
//    func relayClient(_ client: RelayClient, didReceiveMessage message: RelayMessage)
//    func relayClient(_ client: RelayClient, didEncounterError error: RelayError)
//}
//
//public class RelayClient {
//    private var natsClient: NatsClient?
//    private let natsUrl: String
//    private let userID: String
//    
//    public weak var delegate: RelayClientDelegate?
//    
//    private(set) public var connectionStatus: ConnectionStatus = .disconnected {
//        didSet {
//            delegate?.relayClient(self, didChangeConnectionStatus: connectionStatus)
//        }
//    }
//    
//    public enum ConnectionStatus {
//        case connected
//        case disconnected
//        case connecting
//        case error(Error)
//    }
//    
//    public init(natsUrl: String, userID: String) {
//        self.natsUrl = natsUrl
//        self.userID = userID
//    }
//    
//    // MARK: - Connection Management
//    
//    public func connect() async throws {
//        connectionStatus = .connecting
//        
//        do {
//            self.natsClient = NatsClientOptions().url(URL(string: natsUrl)!).build()
//            try await self.natsClient?.connect()
//            connectionStatus = .connected
//        } catch {
//            connectionStatus = .error(error)
//            delegate?.relayClient(self, didEncounterError: .connectionFailed)
//            throw RelayError.connectionFailed
//        }
//    }
//    
//    public func disconnect() async {
//        do {
//            try await natsClient?.close()
//            natsClient = nil
//            connectionStatus = .disconnected
//        } catch {
//            connectionStatus = .error(error)
//            delegate?.relayClient(self, didEncounterError: .connectionFailed)
//        }
//    }
//    
//    // MARK: - Pub/Sub Functionality
//    
//    public func subscribe(to subject: String) async throws -> AsyncThrowingStream<RelayMessage, Error> {
//        guard let client = natsClient else {
//            throw RelayError.notConnected
//        }
//        
//        do {
//            let subscription = try await client.subscribe(subject: subject)
//            
//            // Create a stream with proper @Sendable closure
//            return AsyncThrowingStream { [weak self] continuation in
//                // Create a detached task with explicit priority
//                Task.detached(priority: .userInitiated) {
//                    do {
//                        // Process messages in a serial queue
//                        for try await message in subscription {
//                            // Parse message safely
//                            if let relayMessage = try await self?.parseMessageSafely(message, subject: subject) {
//                                continuation.yield(relayMessage)
//                            }
//                        }
//                        continuation.finish()
//                    } catch {
//                        continuation.finish(throwing: error)
//                    }
//                }
//            }
//        } catch {
//            delegate?.relayClient(self, didEncounterError: .subscriptionFailed)
//            throw RelayError.subscriptionFailed
//        }
//    }
//
//    // Thread-safe message parsing
//    private nonisolated func parseMessageSafely(_ message: NatsMessage, subject: String) async throws -> RelayMessage {
//        // Perform parsing in a detached context
//        return try await Task.detached {
//            guard let payload = message.payload,
//                  let messageString = String(data: payload, encoding: .utf8) else {
//                throw RelayError.invalidMessageFormat
//            }
//            
//            let components = messageString.split(separator: ":", maxSplits: 1).map(String.init)
//            guard components.count == 2 else {
//                throw RelayError.invalidMessageFormat
//            }
//            
//            return RelayMessage(
//                senderID: components[0],
//                content: components[1],
//                subject: subject,
//                timestamp: Date()
//            )
//        }.value
//    }
//    public func publish(message: String, to subject: String) async throws {
//        guard let client = natsClient else {
//            throw RelayError.notConnected
//        }
//        
//        let formattedMessage = "\(userID):\(message)"
//        guard let data = formattedMessage.data(using: .utf8) else {
//            throw RelayError.publishFailed
//        }
//        
//        do {
//            // Updated publish API
//            try await client.publish(data, subject: subject)
//            
//            // Notify delegate about the sent message
//            let relayMessage = RelayMessage(
//                senderID: userID,
//                content: message,
//                subject: subject
//            )
//            
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                self.delegate?.relayClient(self, didReceiveMessage: relayMessage)
//            }
//        } catch {
//            delegate?.relayClient(self, didEncounterError: .publishFailed)
//            throw RelayError.publishFailed
//        }
//    }
//}
//
