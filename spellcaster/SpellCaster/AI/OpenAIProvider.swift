import Foundation

/// OpenAI-compatible provider with streaming support
class OpenAIProvider: AIProvider {
    private let config: AIProviderConfig
    private let session: URLSession
    
    init(config: AIProviderConfig) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    func sendMessage(
        messages: [AIMessage],
        context: ContextSnapshot
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard let apiKey = config.apiKey else {
            throw OpenAIError.missingAPIKey
        }
        
        // Build request
        let baseURL = config.baseURL ?? "https://api.openai.com/v1"
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build request body
        let requestBody = OpenAIRequest(
            model: config.providerType,
            messages: messages.map { message in
                OpenAIMessage(
                    role: message.role.rawValue,
                    content: message.content
                )
            },
            temperature: config.temperature,
            maxTokens: config.maxTokens,
            topP: config.topP,
            stream: true
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Create streaming response
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OpenAIError.invalidResponse
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        throw OpenAIError.httpError(httpResponse.statusCode)
                    }
                    
                    // Parse SSE stream
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            
                            if data == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            if let jsonData = data.data(using: .utf8),
                               let chunk = try? JSONDecoder().decode(OpenAIStreamChunk.self, from: jsonData),
                               let content = chunk.choices.first?.delta.content {
                                continuation.yield(content)
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

// MARK: - OpenAI Models

private struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int?
    let topP: Double?
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case stream
    }
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAIStreamChunk: Codable {
    let choices: [OpenAIChoice]
}

private struct OpenAIChoice: Codable {
    let delta: OpenAIDelta
}

private struct OpenAIDelta: Codable {
    let content: String?
}

// MARK: - OpenAI Error

enum OpenAIError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
