import SwiftUI
import AppKit

/// Bridge between SwiftUI and AppKit TerminalView
struct TerminalViewRepresentable: NSViewRepresentable {
    @ObservedObject var paneViewModel: PaneViewModel
    
    func makeNSView(context: Context) -> TerminalView {
        let profile = ProfileManager.shared.getDefaultProfile()
        let terminalView = TerminalView(state: paneViewModel.terminalState, profile: profile)
        
        // Set up key event handling
        terminalView.onKeyEvent = { [weak paneViewModel] event in
            guard let paneViewModel = paneViewModel else { return }
            if let data = TerminalInput.encode(
                event: event,
                applicationCursorKeys: paneViewModel.terminalState.applicationCursorKeys,
                applicationKeypad: paneViewModel.terminalState.applicationKeypad
            ) {
                try? paneViewModel.sendInput(data)
            }
        }
        
        // Set up resize handling
        terminalView.onResize = { [weak paneViewModel] rows, columns in
            guard let paneViewModel = paneViewModel else { return }
            try? paneViewModel.resize(rows: rows, columns: columns)
        }
        
        // Set up paste handling
        terminalView.onPaste = { [weak paneViewModel] text in
            guard let paneViewModel = paneViewModel else { return }
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
        // Update the terminal view when the state changes
        nsView.setNeedsDisplay(nsView.bounds)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(paneViewModel: paneViewModel)
    }
    
    class Coordinator {
        let paneViewModel: PaneViewModel
        
        init(paneViewModel: PaneViewModel) {
            self.paneViewModel = paneViewModel
        }
    }
}
