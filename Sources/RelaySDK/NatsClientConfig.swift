//
//  NatsClientConfig.swift
//  RelaySDK
//

import Foundation
import Logging

// Thread-safe logger manager using traditional synchronization
public class LoggerManager: @unchecked Sendable {
    private static let instanceQueue = DispatchQueue(label: "com.relaysdk.logger.instance")
    private static let _shared = LoggerManager()
    
    static var shared: LoggerManager {
        return _shared
    }
    
    private let queue = DispatchQueue(label: "com.relaysdk.logger")
    private(set) var logger: Logger
    
    private init() {
        self.logger = Logger(label: "SwiftyNats")
    }
    
    func setLogLevel(_ level: Logger.Level) {
        queue.sync {
            logger.logLevel = level
        }
    }
}

public let libVersion = "2.2"

public struct NatsClientConfig {
    
    // logging
    public var loglevel: Logger.Level = .error {
        didSet {
            let newLevel = loglevel  // Capture the value instead of self
            DispatchQueue.main.async {
                LoggerManager.shared.setLogLevel(newLevel)
            }
        }
    }
    
    // Required for nats server
    public let verbose: Bool
    public let pedantic: Bool
    public let name: String
    let lang: String = "Swift"
    let version: String = libVersion
    
    // Internal config vars
    public var internalQueueMax: Int = Int.max
    
    public init(
        verbose: Bool = false,
        pedantic: Bool = false,
        name: String = "SwiftyNats \(libVersion)",
        loglevel: Logger.Level? = .error
    ) {
        self.verbose = verbose
        self.pedantic = pedantic
        self.name = name

        if let level = loglevel {
            self.loglevel = level
        }
    }
}

