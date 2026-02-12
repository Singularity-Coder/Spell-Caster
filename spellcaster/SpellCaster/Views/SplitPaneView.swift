import SwiftUI

/// Split pane container (placeholder for future implementation)
struct SplitPaneView: View {
    let panes: [PaneViewModel]
    
    var body: some View {
        // Simple placeholder - full split pane implementation would be more complex
        VStack {
            ForEach(panes) { pane in
                TerminalPaneView(paneViewModel: pane)
            }
        }
    }
}
