import SwiftUI

/// Individual chat message view
struct ChatMessageView: View {
    let message: AIMessage
    let viewModel: AISidebarViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            avatarView
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 8) {
                // Header: role + timestamp
                HStack {
                    Text(roleLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(roleColor)
                    
                    Spacer()
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Message content
                messageContentView
                
                // Command cards
                if !message.commandCards.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(message.commandCards) { card in
                            CommandCardView(card: card, viewModel: viewModel)
                        }
                    }
                }
                
                // Error display
                if case .error(let errorMessage) = message.streamingState {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                }
                
                // Streaming indicator
                if case .streaming = message.streamingState {
                    streamingIndicator
                }
            }
        }
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(roleColor.opacity(0.2))
            
            Image(systemName: roleIcon)
                .font(.system(size: 14))
                .foregroundColor(roleColor)
        }
    }
    
    @ViewBuilder
    private var messageContentView: some View {
        switch message.role {
        case .system:
            systemMessageView
        case .user:
            userMessageView
        case .assistant:
            assistantMessageView
        }
    }
    
    private var systemMessageView: some View {
        Text(message.content)
            .font(.callout)
            .foregroundColor(.secondary)
            .textSelection(.enabled)
    }
    
    private var userMessageView: some View {
        Text(message.content)
            .font(.body)
            .textSelection(.enabled)
    }
    
    private var assistantMessageView: some View {
        Text(message.content)
            .font(.body)
            .textSelection(.enabled)
    }
    
    private var streamingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
            }
            Text("Thinking...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var roleLabel: String {
        switch message.role {
        case .system: return "System"
        case .user: return "You"
        case .assistant: return "AI"
        }
    }
    
    private var roleIcon: String {
        switch message.role {
        case .system: return "gearshape"
        case .user: return "person"
        case .assistant: return "sparkles"
        }
    }
    
    private var roleColor: Color {
        switch message.role {
        case .system: return .secondary
        case .user: return .blue
        case .assistant: return .green
        }
    }
    
    private var backgroundColor: Color {
        switch message.role {
        case .system:
            return Color(NSColor.controlBackgroundColor).opacity(0.5)
        case .user:
            return Color.blue.opacity(0.1)
        case .assistant:
            return Color.gray.opacity(0.1)
        }
    }
}

#Preview {
    let viewModel = AISidebarViewModel(
        session: AISession(),
        paneViewModel: PaneViewModel(profile: .default)
    )
    
    return VStack(spacing: 16) {
        ChatMessageView(
            message: .user("How do I list files in a directory?"),
            viewModel: viewModel
        )
        
        ChatMessageView(
            message: .assistant("You can use the `ls` command to list files. For detailed information, use `ls -la`."),
            viewModel: viewModel
        )
        
        ChatMessageView(
            message: AIMessage(
                role: .assistant,
                content: "```bash\nls -la\n```",
                commandCards: [
                    CommandCard(
                        command: "ls -la",
                        explanation: "List all files with details",
                        riskLevel: .safe
                    )
                ]
            ),
            viewModel: viewModel
        )
    }
    .padding()
    .frame(width: 400)
}
