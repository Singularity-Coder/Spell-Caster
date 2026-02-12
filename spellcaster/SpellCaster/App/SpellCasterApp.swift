import SwiftUI
import AppKit

@main
struct SpellCasterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .commands {
            // Replace default new item with new window (uses native tabs)
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    NSApp.sendAction(#selector(NSApplication.newWindowForTab(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        
        Settings {
            PreferencesView()
        }
    }
}
