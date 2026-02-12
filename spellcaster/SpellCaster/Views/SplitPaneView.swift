import SwiftUI

/// Split pane container for terminal views
struct SplitPaneView: View {
    @ObservedObject var windowViewModel: WindowViewModel
    @FocusState private var isTerminalFocused: Bool
    
    var body: some View {
        // For MVP, just show the active pane
        // Future: Support actual split panes with HSplitView/VSplitView
        if let activePane = windowViewModel.activePane {
            TerminalViewRepresentable(paneViewModel: activePane)
                .focused($isTerminalFocused)
                .onAppear {
                    isTerminalFocused = true
                }
        } else if let firstPane = windowViewModel.panes.first {
            TerminalViewRepresentable(paneViewModel: firstPane)
                .focused($isTerminalFocused)
                .onAppear {
                    isTerminalFocused = true
                }
        } else {
            // No panes available
            VStack {
                Spacer()
                Text("No terminal session")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Press ⌘T to create a new tab")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
        }
    }
}

// Preview removed - would require mocking PTY
