import SwiftUI

/// Split pane container for terminal views
struct SplitPaneView: View {
    @ObservedObject var windowViewModel: WindowViewModel
    
    var body: some View {
        // For MVP, just show the active pane
        // Future: Support actual split panes with HSplitView/VSplitView
        if let activePane = windowViewModel.activePane {
            TerminalViewRepresentable(paneViewModel: activePane)
        } else if let firstPane = windowViewModel.panes.first {
            TerminalViewRepresentable(paneViewModel: firstPane)
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

#Preview {
    SplitPaneView(windowViewModel: WindowViewModel())
        .frame(width: 800, height: 600)
}
