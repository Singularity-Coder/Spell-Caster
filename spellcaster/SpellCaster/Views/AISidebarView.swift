import SwiftUI

/// AI sidebar view with chat interface
struct AISidebarView: View {
    @ObservedObject var session: AISession
    let paneViewModel: PaneViewModel
    @StateObject private var viewModel: AISidebarViewModel
    @State private var inputText: String = ""
    
    init(session: AISession, paneViewModel: PaneViewModel) {
        self.session = session
        self.paneViewModel = paneViewModel
        self._viewModel = StateObject(wrappedValue: AISidebarViewModel(session: session, paneViewModel: paneViewModel))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                
                Spacer()
                
                // Model selection
                Menu {
                    Button("GPT-4") {
                        session.selectedModel = "gpt-4"
                    }
                    Button("GPT-3.5 Turbo") {
                        session.selectedModel = "gpt-3.5-turbo"
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(session.selectedModel)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                }
                .menuStyle(.borderlessButton)
                
                // Clear button
                Button(action: { session.clearMessages() }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .help("Clear Chat")
            }
            .padding()
            
            Divider()
            
            // Chat transcript
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(session.messages) { message in
                            ChatMessageView(message: message, viewModel: viewModel)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: session.messages.count) { _ in
                    // Auto-scroll to bottom when new message arrives
                    if let lastMessage = session.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Attach button (left of input)
                Button(action: {
                    // TODO: Attach terminal selection
                }) {
                    Image(systemName: "paperclip")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Attach Selection")
                
                // Input field
                TextField("Ask AI...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .lineLimit(1...5)
                    .onSubmit {
                        sendMessage()
                    }
                
                // Send/Stop button
                if viewModel.isProcessing {
                    Button(action: {
                        viewModel.cancelStreaming()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Stop Generating")
                } else {
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundColor(inputText.isEmpty ? .secondary : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty)
                    .help("Send Message")
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        viewModel.sendMessage(inputText)
        inputText = ""
    }
}

#Preview {
    let session = AISession()
    let paneViewModel = PaneViewModel(profile: .default)
    
    return AISidebarView(session: session, paneViewModel: paneViewModel)
        .frame(width: 350, height: 600)
}
