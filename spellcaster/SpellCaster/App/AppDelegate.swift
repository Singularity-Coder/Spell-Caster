import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app-wide settings
        configureAppearance()
        
        // Set up window management
        setupWindowManagement()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up any running PTY processes
        WindowManager.shared.cleanupAllProcesses()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Private Methods
    
    private func configureAppearance() {
        // Allow windows to have full-size content view
        NSWindow.allowsAutomaticWindowTabbing = true
    }
    
    private func setupWindowManagement() {
        // Configure window restoration
        NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
    }
    
    // MARK: - Menu Actions
    
    @objc func newWindow(_ sender: Any?) {
        WindowManager.shared.createNewWindow()
    }
    
    @objc func newTab(_ sender: Any?) {
        WindowManager.shared.createNewTab()
    }
    
    @objc func splitHorizontally(_ sender: Any?) {
        WindowManager.shared.splitPaneHorizontally()
    }
    
    @objc func splitVertically(_ sender: Any?) {
        WindowManager.shared.splitPaneVertically()
    }
    
    @objc func toggleAISidebar(_ sender: Any?) {
        WindowManager.shared.toggleAISidebar()
    }
    
    @objc func clearScrollback(_ sender: Any?) {
        WindowManager.shared.clearScrollback()
    }
    
    @objc func resetTerminal(_ sender: Any?) {
        WindowManager.shared.resetTerminal()
    }
}
