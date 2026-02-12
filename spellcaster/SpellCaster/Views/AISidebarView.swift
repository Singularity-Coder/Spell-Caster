import SwiftUI

/// AI sidebar view
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
                Button(action: { session.clearMessages() }) {
                    Image(systemName: "trash")
                }
            }
            .padding()
            
            Divider()
            
            // Chat transcript
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(session.messages) { message in
                        ChatMessageView(message: message, viewModel: viewModel)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Input area
            HStack {
                TextField("Ask AI...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(inputText.isEmpty || viewModel.isProcessing)
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
