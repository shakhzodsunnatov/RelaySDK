//// The Swift Programming Language
//// https://docs.swift.org/swift-book
//
//import Foundation
//import Nats
//
//public class RelaySDK {
//    private let natsClient: NatsClient
//    private let baseURL: String
//    private let queue: DispatchQueue
//
//    public init(natsURL: String, apiBaseURL: String) {
//        self.baseURL = apiBaseURL
//        self.natsClient = NatsClient(natsURL)
//        self.queue = DispatchQueue(label: "com.relay.sdk.queue", attributes: .concurrent)
//    }
//
//    // MARK: - Connection Management
//    public func connect(completion: @escaping @Sendable (Bool, String?) -> Void) {
//        queue.async { [weak self] in
//            guard let self = self else { return }
//
//            // Create a local copy of the event to avoid capturing self
//            self.natsClient.on([.connected, .disconnected]) { [weak self] event in
//                // Capture only the raw value which is Sendable
//                let eventValue = event.rawValue
//                let result = (event == .connected, eventValue)
////                completion(event == .connected, eventValue)
//                DispatchQueue.main.async {
//                    completion(result.0, result.1)
//                }
//            }
//        }
//    }
//
//    // MARK: - Publishing Messages
//    public func publish(to subject: String, message: String) {
//        queue.async { [weak self] in
//            self?.natsClient.publish(message, to: subject)
//        }
//    }
//
//    // MARK: - Subscribing to Messages
//    public func subscribe(to subject: String, handler: @Sendable @escaping (String) -> Void) {
//        queue.async { [weak self] in
//            guard let self = self else { return }
//
//            self.natsClient.subscribe(to: subject) { message in
//                // Extract only the payload which is Sendable
//                let payload = message.payload ?? "EMPTY"
//                DispatchQueue.main.async {
//                    handler(payload)
//                }
//            }
//        }
//    }
//    
//    // MARK: - Fetching Historical Data
//    public func fetchHistory(for topic: String, completion: @escaping @Sendable (Result<[String], Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/history?topic=\(topic)") else {
//            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//            return
//        }
//        
//        queue.async {
//            URLSession.shared.dataTask(with: url) { data, _, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                guard let data = data, let response = try? JSONDecoder().decode([String].self, from: data) else {
//                    completion(.failure(NSError(domain: "Invalid data", code: 0, userInfo: nil)))
//                    return
//                }
//                completion(.success(response))
//            }.resume()
//        }
//    }
//}
//
//
////import Nats
////
////public class RelaySDK {
////    private var connection: Connection?
////    private let subject: String
////    
////    public init(subject: String) {
////        self.subject = subject
////    }
////    
////    public func connect(completion: @escaping (Bool, String?) -> Void) {
////        do {
////            let conn = try Connection(url: "nats://localhost:4222")
////            self.connection = conn
////            completion(true, nil)
////        } catch {
////            completion(false, error.localizedDescription)
////        }
////    }
////    
////    public func publish(message: String) {
////        guard let conn = connection else { return }
////        try? conn.publish(subject, string: message)
////    }
////    
////    public func subscribe(handler: @escaping (String) -> Void) {
////        guard let conn = connection else { return }
////        try? conn.subscribe(subject) { message in
////            if let data = message.string {
////                handler(data)
////            }
////        }
////    }
////}
