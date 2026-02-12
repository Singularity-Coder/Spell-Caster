import SwiftUI

/// Main window layout (terminal + sidebar)
struct MainWindowView: View {
    @StateObject private var windowViewModel = WindowViewModel()
    
    var body: some View {
        HSplitView {
            // Terminal area
            TerminalPaneView(paneViewModel: windowViewModel.activePane ?? windowViewModel.panes.first!)
                .frame(minWidth: 400)
            
            // AI Sidebar (toggleable)
            if windowViewModel.sidebarVisible {
                AISidebarView(
                    session: windowViewModel.aiSession,
                    paneViewModel: windowViewModel.activePane ?? windowViewModel.panes.first!
                )
                .frame(width: 350)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

/// Terminal pane view wrapping NSView
struct TerminalPaneView: NSViewRepresentable {
    let paneViewModel: PaneViewModel
    
    func makeNSView(context: Context) -> TerminalView {
        let profile = ProfileManager.shared.getDefaultProfile()
        let terminalView = TerminalView(state: paneViewModel.terminalState, profile: profile)
        
        terminalView.onKeyEvent = { event in
            if let data = TerminalInput.encode(
                event: event,
                applicationCursorKeys: paneViewModel.terminalState.applicationCursorKeys,
                applicationKeypad: paneViewModel.terminalState.applicationKeypad
            ) {
                try? paneViewModel.sendInput(data)
            }
        }
        
        terminalView.onResize = { rows, columns in
            try? paneViewModel.resize(rows: rows, columns: columns)
        }
        
        terminalView.onPaste = { text in
            if paneViewModel.terminalState.bracketedPaste {
                if let data = TerminalInput.encodeBracketedPaste(text) {
                    try? paneViewModel.sendInput(data)
                }
            } else {
                try? paneViewModel.sendInput(text)
            }
        }
        
        return terminalView
    }
    
    func updateNSView(_ nsView: TerminalView, context: Context) {
        // Update view if needed
    }
}
