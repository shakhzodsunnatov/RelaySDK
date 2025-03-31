import Foundation

/// A client for making REST API calls to the Relay service
internal final class RelayAPIClient {
    
    // MARK: - Properties
    
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger = LoggerManager.shared.logger
    
    // MARK: - Initialization
    
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - API Methods
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            completion(.failure(RelayError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        
        logger.debug("Making API request to: \(endpoint)")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("API request failed: \(error.localizedDescription)")
                completion(.failure(RelayError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("Invalid response type")
                completion(.failure(RelayError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.logger.error("API error: status code \(httpResponse.statusCode)")
                completion(.failure(RelayError.apiError("Status code: \(httpResponse.statusCode)")))
                return
            }
            
            guard let data = data else {
                self.logger.error("No data in response")
                completion(.failure(RelayError.invalidResponse))
                return
            }
            
            do {
                let decoded = try self.decoder.decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                self.logger.error("Failed to decode response: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Queue API Methods
    
    func createQueue(_ name: String, completion: @escaping (Result<QueueInfo, Error>) -> Void) {
        let body = try? encoder.encode(["name": name])
        request(endpoint: "queues", method: "POST", body: body, completion: completion)
    }
    
    func getQueueInfo(_ name: String, completion: @escaping (Result<QueueInfo, Error>) -> Void) {
        request(endpoint: "queues/\(name)", completion: completion)
    }
    
    // MARK: - History API Methods
    
    func getHistory(
        subject: String,
        startTime: Date?,
        endTime: Date?,
        limit: Int,
        completion: @escaping (Result<[HistoryMessage], Error>) -> Void
    ) {
        var queryItems = [URLQueryItem]()
        
        if let startTime = startTime {
            queryItems.append(URLQueryItem(name: "start_time", value: ISO8601DateFormatter().string(from: startTime)))
        }
        
        if let endTime = endTime {
            queryItems.append(URLQueryItem(name: "end_time", value: ISO8601DateFormatter().string(from: endTime)))
        }
        
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        
        var components = URLComponents()
        components.path = "history/\(subject)"
        components.queryItems = queryItems
        
        guard let endpoint = components.string else {
            completion(.failure(RelayError.invalidResponse))
            return
        }
        
        request(endpoint: endpoint, completion: completion)
    }
} 