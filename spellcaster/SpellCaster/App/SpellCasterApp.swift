import SwiftUI
import AppKit

@main
struct SpellCasterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Use WindowGroup - AppDelegate.createInitialWindow will be called automatically
        WindowGroup {
            MainWindowView()
                .environmentObject(WindowManager.shared)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    WindowManager.shared.createNewWindow()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Tab") {
                    WindowManager.shared.createNewTab()
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
        
        Settings {
            PreferencesView()
        }
    }
}
