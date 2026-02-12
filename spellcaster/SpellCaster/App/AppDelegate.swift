import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enable native window tabbing
        NSWindow.allowsAutomaticWindowTabbing = true
        
        // Set activation policy
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up any running PTY processes
        // PTY processes will be cleaned up when their views are deallocated
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
