import SwiftUI

/// Individual chat message view
struct ChatMessageView: View {
    let message: AIMessage
    let viewModel: AISidebarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Role indicator
            HStack {
                Text(message.role == .user ? "You" : "AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Message content
            Text(message.content)
                .textSelection(.enabled)
            
            // Command cards
            if !message.commandCards.isEmpty {
                VStack(spacing: 8) {
                    ForEach(message.commandCards) { card in
                        CommandCardView(card: card, viewModel: viewModel)
                    }
                }
            }
            
            // Streaming indicator
            if case .streaming = message.streamingState {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .padding()
        .background(message.role == .user ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
