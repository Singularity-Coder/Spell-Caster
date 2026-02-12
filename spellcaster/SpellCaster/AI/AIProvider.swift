import Foundation

/// Protocol for AI providers
protocol AIProvider {
    /// Send a message and receive streaming response
    func sendMessage(
        messages: [AIMessage],
        context: ContextSnapshot
    ) async throws -> AsyncThrowingStream<String, Error>
}

/// AI provider configuration
struct AIProviderConfiguration {
    let apiKey: String
    let baseURL: String
    let model: String
    let temperature: Double
    let maxTokens: Int?
    let topP: Double?
    
    init(
        apiKey: String,
        baseURL: String = "https://api.openai.com/v1",
        model: String = "gpt-4",
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        topP: Double? = nil
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
    }
}
