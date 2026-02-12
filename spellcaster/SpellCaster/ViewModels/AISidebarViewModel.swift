import Foundation
import Combine
import AppKit

/// AI sidebar logic
class AISidebarViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published var isProcessing: Bool = false
    @Published var error: String?
    
    private let session: AISession
    private let paneViewModel: PaneViewModel
    private var aiProvider: AIProvider?
    private var streamTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(session: AISession, paneViewModel: PaneViewModel) {
        self.session = session
        self.paneViewModel = paneViewModel
        
        setupAIProvider()
    }
    
    // MARK: - Setup
    
    private func setupAIProvider() {
        // Create AI provider based on config
        switch session.providerConfig.providerType {
        case "openai":
            aiProvider = OpenAIProvider(config: session.providerConfig)
        default:
            aiProvider = OpenAIProvider(config: session.providerConfig)
        }
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ content: String) {
        guard !isProcessing else { return }
        
        // Add user message
        let userMessage = AIMessage.user(content)
        session.addMessage(userMessage)
        
        // Capture context
        let context = captureContext()
        
        // Start streaming response
        streamResponse(context: context)
    }
    
    private func streamResponse(context: ContextSnapshot) {
        isProcessing = true
        error = nil
        
        // Add assistant message placeholder
        let assistantMessage = AIMessage(
            role: .assistant,
            content: "",
            streamingState: .streaming
        )
        session.addMessage(assistantMessage)
        
        streamTask = Task {
            do {
                guard let provider = aiProvider else {
                    throw AIError.providerNotConfigured
                }
                
                // Build messages with context
                var messages = buildMessages(with: context)
                
                // Stream response
                let stream = try await provider.sendMessage(messages: messages, context: context)
                
                for try await chunk in stream {
                    await MainActor.run {
                        session.updateLastMessage { message in
                            message.content += chunk
                        }
                    }
                }
                
                // Mark as complete
                await MainActor.run {
                    session.updateLastMessage { message in
                        message.streamingState = .complete
                    }
                    
                    // Extract command cards if present
                    extractCommandCards()
                    
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    session.updateLastMessage { message in
                        message.streamingState = .error(error.localizedDescription)
                    }
                    isProcessing = false
                }
            }
        }
    }
    
    func cancelStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isProcessing = false
        
        session.updateLastMessage { message in
            message.streamingState = .complete
        }
    }
    
    // MARK: - Command Card Actions
    
    func insertCommand(_ card: CommandCard) {
        // Insert command at cursor without executing
        try? paneViewModel.sendInput(card.command)
    }
    
    func runCommand(_ card: CommandCard) {
        // Insert and execute command
        try? paneViewModel.sendInput(card.command + "\n")
    }
    
    func copyCommand(_ card: CommandCard) {
        // Copy to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(card.command, forType: .string)
    }
    
    // MARK: - Context Capture
    
    private func captureContext() -> ContextSnapshot {
        let builder = AIContextBuilder(
            paneViewModel: paneViewModel,
            toggles: session.contextToggles
        )
        return builder.build()
    }
    
    private func buildMessages(with context: ContextSnapshot) -> [AIMessage] {
        var messages: [AIMessage] = []
        
        // Add system prompt
        let systemPrompt = PromptPresets.getPrompt(for: session.systemPromptPreset)
        messages.append(.system(systemPrompt))
        
        // Add context as system message
        let contextPrompt = "Terminal Context:\n\n" + context.formatForPrompt()
        messages.append(.system(contextPrompt))
        
        // Add conversation history
        messages.append(contentsOf: session.messages)
        
        return messages
    }
    
    private func extractCommandCards() {
        // Parse last message for command blocks
        guard let lastMessage = session.messages.last else { return }
        
        let content = lastMessage.content
        var cards: [CommandCard] = []
        
        // Simple regex to find code blocks with shell/bash
        let pattern = "```(?:shell|bash)\\s*\\n([^`]+)```"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = content as NSString
            let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges > 1 {
                    let commandRange = match.range(at: 1)
                    let command = nsString.substring(with: commandRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let card = CommandCard(
                        command: command,
                        explanation: "AI-suggested command",
                        riskLevel: assessRiskLevel(command)
                    )
                    cards.append(card)
                }
            }
        }
        
        // Update message with cards
        if !cards.isEmpty {
            session.updateLastMessage { message in
                message.commandCards = cards
            }
        }
    }
    
    private func assessRiskLevel(_ command: String) -> RiskLevel {
        let dangerousCommands = ["rm", "dd", "mkfs", "format", ">", "sudo rm"]
        let cautionCommands = ["mv", "cp", "chmod", "chown", "sudo"]
        
        for dangerous in dangerousCommands {
            if command.contains(dangerous) {
                return .danger
            }
        }
        
        for caution in cautionCommands {
            if command.contains(caution) {
                return .caution
            }
        }
        
        return .safe
    }
}

// MARK: - AI Error

enum AIError: Error, LocalizedError {
    case providerNotConfigured
    case invalidResponse
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .providerNotConfigured:
            return "AI provider is not configured"
        case .invalidResponse:
            return "Invalid response from AI provider"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
