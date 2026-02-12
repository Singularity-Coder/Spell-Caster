import SwiftUI
import AppKit

@main
struct SpellCasterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .navigationTitle("Spell Caster")
        }
        .windowStyle(.automatic)
        .commands {
            // Replace default new item with new window (uses native tabs)
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    // Create new window - macOS will handle tabbing
                    NSApp.sendAction(#selector(NSApplication.newWindowForTab(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Tab") {
                    // Create new tab in current window
                    NSApp.sendAction(#selector(NSApplication.newWindowForTab(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            
            // Add window menu commands for tab management
            CommandGroup(after: .windowArrangement) {
                Button("Merge All Windows") {
                    // Use the window menu action
                    if let window = NSApp.keyWindow {
                        window.tabbingMode = .preferred
                    }
                    // Trigger merge via first responder
                    NSApp.sendAction(#selector(NSWindow.toggleTabBar(_:)), to: nil, from: nil)
                }
                
                Divider()
                
                Button("Toggle Tab Bar") {
                    NSApp.sendAction(#selector(NSWindow.toggleTabBar(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            PreferencesView()
        }
    }
}
