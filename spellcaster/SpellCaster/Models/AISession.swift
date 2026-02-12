import Foundation
import Combine

/// AI session state per window
class AISession: ObservableObject {
    // MARK: - Published Properties
    
    @Published var messages: [AIMessage] = []
    @Published var isStreaming: Bool = false
    @Published var selectedModel: String
    @Published var providerConfig: AIProviderConfig
    @Published var contextToggles: ContextToggles
    @Published var systemPromptPreset: String
    @Published var error: Error?
    
    // MARK: - Properties
    
    let id: UUID
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        selectedModel: String = "gpt-4",
        providerConfig: AIProviderConfig = AIProviderConfig(),
        systemPromptPreset: String = "shell-assistant"
    ) {
        self.id = id
        self.selectedModel = selectedModel
        self.providerConfig = providerConfig
        self.contextToggles = ContextToggles()
        self.systemPromptPreset = systemPromptPreset
    }
    
    // MARK: - Message Management
    
    func addMessage(_ message: AIMessage) {
        messages.append(message)
    }
    
    func clearMessages() {
        messages.removeAll()
    }
    
    func updateLastMessage(_ update: (inout AIMessage) -> Void) {
        guard !messages.isEmpty else { return }
        update(&messages[messages.count - 1])
    }
    
    // MARK: - Context Management
    
    func toggleContext(_ context: ContextType) {
        switch context {
        case .currentDirectory:
            contextToggles.includeCurrentDirectory.toggle()
        case .recentOutput:
            contextToggles.includeRecentOutput.toggle()
        case .lastCommand:
            contextToggles.includeLastCommand.toggle()
        case .gitStatus:
            contextToggles.includeGitStatus.toggle()
        case .selection:
            contextToggles.includeSelection.toggle()
        case .environment:
            contextToggles.includeEnvironment.toggle()
        case .scrollback:
            contextToggles.includeScrollback.toggle()
        }
    }
}

// MARK: - AI Provider Config

struct AIProviderConfig: Codable {
    var providerType: String
    var apiKey: String?
    var baseURL: String?
    var temperature: Double
    var maxTokens: Int?
    var topP: Double?
    
    init(
        providerType: String = "openai",
        apiKey: String? = nil,
        baseURL: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        topP: Double? = nil
    ) {
        self.providerType = providerType
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
    }
}

// MARK: - Context Toggles

struct ContextToggles {
    var includeCurrentDirectory: Bool = true
    var includeRecentOutput: Bool = true
    var includeLastCommand: Bool = true
    var includeGitStatus: Bool = true
    var includeSelection: Bool = true
    var includeEnvironment: Bool = false
    var includeScrollback: Bool = false
}

enum ContextType {
    case currentDirectory
    case recentOutput
    case lastCommand
    case gitStatus
    case selection
    case environment
    case scrollback
}
