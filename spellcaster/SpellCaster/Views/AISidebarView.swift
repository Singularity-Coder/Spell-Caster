import SwiftUI

/// AI sidebar view with chat interface
struct AISidebarView: View {
    @ObservedObject var session: AISession
    let paneViewModel: PaneViewModel
    @StateObject private var viewModel: AISidebarViewModel
    @State private var inputText: String = ""
    @State private var showContextInspector: Bool = false
    
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
            
            // Prompt preset selector
            HStack {
                Text("Preset:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $session.systemPromptPreset) {
                    Text("Shell Assistant").tag("shell-assistant")
                    Text("DevOps").tag("devops")
                    Text("Python").tag("python")
                    Text("Git").tag("git")
                }
                .pickerStyle(.menu)
                .font(.caption)
                
                Spacer()
                
                // Context inspector toggle
                Button(action: { showContextInspector.toggle() }) {
                    Image(systemName: showContextInspector ? "info.circle.fill" : "info.circle")
                }
                .buttonStyle(.plain)
                .help("Context Inspector")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Context inspector (collapsible)
            if showContextInspector {
                ContextInspectorView(
                    context: paneViewModel.captureContext(),
                    toggles: $session.contextToggles
                )
                .frame(maxHeight: 200)
                
                Divider()
            }
            
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
            VStack(spacing: 8) {
                // Context toggles (compact)
                HStack(spacing: 12) {
                    ContextToggleButton(
                        icon: "folder",
                        isOn: session.contextToggles.includeCurrentDirectory,
                        action: { session.toggleContext(.currentDirectory) }
                    )
                    ContextToggleButton(
                        icon: "doc.text",
                        isOn: session.contextToggles.includeRecentOutput,
                        action: { session.toggleContext(.recentOutput) }
                    )
                    ContextToggleButton(
                        icon: "terminal",
                        isOn: session.contextToggles.includeLastCommand,
                        action: { session.toggleContext(.lastCommand) }
                    )
                    ContextToggleButton(
                        icon: "arrow.triangle.branch",
                        isOn: session.contextToggles.includeGitStatus,
                        action: { session.toggleContext(.gitStatus) }
                    )
                    
                    Spacer()
                    
                    // Attach selection button
                    Button(action: {
                        // TODO: Attach terminal selection
                    }) {
                        Image(systemName: "paperclip")
                    }
                    .buttonStyle(.plain)
                    .help("Attach Selection")
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Input field
                HStack(alignment: .bottom, spacing: 8) {
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
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        viewModel.sendMessage(inputText)
        inputText = ""
    }
}

/// Context toggle button
struct ContextToggleButton: View {
    let icon: String
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(isOn ? .accentColor : .secondary)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let session = AISession()
    let paneViewModel = PaneViewModel(profile: .default)
    
    return AISidebarView(session: session, paneViewModel: paneViewModel)
        .frame(width: 350, height: 600)
}
