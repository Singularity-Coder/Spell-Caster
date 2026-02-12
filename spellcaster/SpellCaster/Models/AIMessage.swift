import Foundation

/// Chat message model for AI conversations
struct AIMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var commandCards: [CommandCard]
    var streamingState: StreamingState
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        commandCards: [CommandCard] = [],
        streamingState: StreamingState = .complete
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.commandCards = commandCards
        self.streamingState = streamingState
    }
    
    /// Create a user message
    static func user(_ content: String) -> AIMessage {
        return AIMessage(role: .user, content: content)
    }
    
    /// Create an assistant message
    static func assistant(_ content: String, commandCards: [CommandCard] = []) -> AIMessage {
        return AIMessage(role: .assistant, content: content, commandCards: commandCards)
    }
    
    /// Create a system message
    static func system(_ content: String) -> AIMessage {
        return AIMessage(role: .system, content: content)
    }
}

// MARK: - Message Role

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - Streaming State

enum StreamingState: Codable {
    case streaming
    case complete
    case error(String)
    
    enum CodingKeys: String, CodingKey {
        case type
        case errorMessage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "streaming":
            self = .streaming
        case "complete":
            self = .complete
        case "error":
            let message = try container.decode(String.self, forKey: .errorMessage)
            self = .error(message)
        default:
            self = .complete
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .streaming:
            try container.encode("streaming", forKey: .type)
        case .complete:
            try container.encode("complete", forKey: .type)
        case .error(let message):
            try container.encode("error", forKey: .type)
            try container.encode(message, forKey: .errorMessage)
        }
    }
}
