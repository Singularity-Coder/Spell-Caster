import SwiftUI
import AppKit

@main
struct SpellCasterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var windowManager = WindowManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(windowManager)
        }
        .commands {
            // File menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    windowManager.createNewWindow()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Tab") {
                    windowManager.createNewTab()
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            
            // Edit menu commands
            CommandGroup(after: .pasteboard) {
                Divider()
                Button("Select All") {
                    // Will be handled by TerminalView
                }
                .keyboardShortcut("a", modifiers: .command)
            }
            
            // View menu commands
            CommandMenu("View") {
                Button("Toggle AI Sidebar") {
                    windowManager.toggleAISidebar()
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Split Pane Horizontally") {
                    windowManager.splitPaneHorizontally()
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Split Pane Vertically") {
                    windowManager.splitPaneVertically()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            
            // Shell menu commands
            CommandMenu("Shell") {
                Button("Clear Scrollback") {
                    windowManager.clearScrollback()
                }
                .keyboardShortcut("k", modifiers: .command)
                
                Button("Reset Terminal") {
                    windowManager.resetTerminal()
                }
                .keyboardShortcut("r", modifiers: [.command, .option])
            }
        }
        
        Settings {
            PreferencesView()
        }
    }
}
