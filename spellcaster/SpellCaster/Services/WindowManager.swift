import Foundation
import SwiftUI
import Combine

/// Window lifecycle management
class WindowManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = WindowManager()
    
    // MARK: - Properties
    
    @Published var windows: [WindowViewModel] = []
    @Published var activeWindowID: UUID?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        // Listen for window close notifications
        NotificationCenter.default.publisher(for: .windowShouldClose)
            .sink { [weak self] notification in
                if let window = notification.object as? WindowViewModel {
                    self?.closeWindow(window)
                }
            }
            .store(in: &cancellables)
    }
    
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
        return windows.first(where: { $0.id == id }) ?? windows.first
    }
    
    // MARK: - Tab Management
    
    func createNewTab() {
        if let window = activeWindow {
            window.createPane()
        } else {
            createNewWindow()
        }
    }
    
    // MARK: - Split Pane Management
    
    func splitPaneHorizontally() {
        if let window = activeWindow {
            window.splitPaneHorizontally()
        }
    }
    
    func splitPaneVertically() {
        if let window = activeWindow {
            window.splitPaneVertically()
        }
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
