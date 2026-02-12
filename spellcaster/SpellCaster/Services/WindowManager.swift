import Foundation
import SwiftUI

/// Window lifecycle management
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var windows: [WindowViewModel] = []
    @Published var activeWindowID: UUID?
    
    private init() {}
    
    // MARK: - Window Management
    
    func createNewWindow() {
        let window = WindowViewModel()
        windows.append(window)
        activeWindowID = window.id
    }
    
    func closeWindow(_ window: WindowViewModel) {
        window.cleanup()
        windows.removeAll(where: { $0.id == window.id })
        
        if activeWindowID == window.id {
            activeWindowID = windows.first?.id
        }
    }
    
    func setActiveWindow(_ window: WindowViewModel) {
        activeWindowID = window.id
    }
    
    var activeWindow: WindowViewModel? {
        guard let id = activeWindowID else { return windows.first }
        return windows.first(where: { $0.id == id })
    }
    
    // MARK: - Tab Management
    
    func createNewTab() {
        activeWindow?.createPane()
    }
    
    // MARK: - Split Pane Management
    
    func splitPaneHorizontally() {
        // TODO: Implement split pane logic
        activeWindow?.createPane()
    }
    
    func splitPaneVertically() {
        // TODO: Implement split pane logic
        activeWindow?.createPane()
    }
    
    // MARK: - Sidebar Management
    
    func toggleAISidebar() {
        activeWindow?.toggleSidebar()
    }
    
    // MARK: - Terminal Operations
    
    func clearScrollback() {
        activeWindow?.clearScrollback()
    }
    
    func resetTerminal() {
        activeWindow?.resetTerminal()
    }
    
    // MARK: - Cleanup
    
    func cleanupAllProcesses() {
        windows.forEach { $0.cleanup() }
        windows.removeAll()
    }
}
