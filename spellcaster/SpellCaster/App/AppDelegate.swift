import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    
    private var windowControllers: [NSWindowController] = []
    private var hasCreatedWindow = false
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app-wide settings
        configureAppearance()
        
        // Set up window management
        setupWindowManagement()
        
        // Note: Window is created automatically by WindowGroup
        // Additional windows can be created via WindowManager.createNewWindow()
        hasCreatedWindow = true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up any running PTY processes
        WindowManager.shared.cleanupAllProcesses()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // We handle window creation manually
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Window Management
    
    private func createInitialWindow() {
        WindowManager.shared.createNewWindow()
    }
    
    // MARK: - Configuration
    
    private func configureAppearance() {
        // Allow windows to have full-size content view
        NSWindow.allowsAutomaticWindowTabbing = true
        
        // Set activation policy
        NSApp.setActivationPolicy(.regular)
    }
    
    private func setupWindowManagement() {
        // Configure window restoration
        NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
        // Register for window close notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowShouldClose(_:)),
            name: .windowShouldClose,
            object: nil
        )
    }
    
    @objc private func handleWindowShouldClose(_ notification: Notification) {
        if let windowViewModel = notification.object as? WindowViewModel {
            WindowManager.shared.closeWindow(windowViewModel)
        }
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
    
    @objc func showPreferences(_ sender: Any?) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
