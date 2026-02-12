import Foundation
import SwiftUI
import AppKit
import Combine

/// Window lifecycle management
class WindowManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = WindowManager()
    
    // MARK: - Properties
    
    @Published var windows: [WindowViewModel] = []
    @Published var activeWindowID: UUID?
    
    private var cancellables = Set<AnyCancellable>()
    private var nsWindows: [UUID: NSWindow] = [:]
    
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
        let windowViewModel = WindowViewModel()
        windows.append(windowViewModel)
        activeWindowID = windowViewModel.id
        
        // Create and show the NSWindow
        let contentView = MainWindowView()
            .environmentObject(windowViewModel)
            .environmentObject(self)
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let nsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        nsWindow.title = "Spell Caster"
        nsWindow.contentViewController = hostingController
        nsWindow.center()
        nsWindow.setFrameAutosaveName("SpellCasterMainWindow")
        nsWindow.minSize = NSSize(width: 800, height: 600)
        nsWindow.titlebarAppearsTransparent = false
        nsWindow.titleVisibility = .visible
        nsWindow.isReleasedWhenClosed = false
        
        // Store reference
        nsWindows[windowViewModel.id] = nsWindow
        
        // Show window
        nsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeWindow(_ window: WindowViewModel) {
        // Close and release the NSWindow
        if let nsWindow = nsWindows[window.id] {
            nsWindow.close()
            nsWindows.removeValue(forKey: window.id)
        }
        
        window.cleanup()
        windows.removeAll(where: { $0.id == window.id })
        
        if activeWindowID == window.id {
            activeWindowID = windows.first?.id
        }
    }
    
    func setActiveWindow(_ window: WindowViewModel) {
        activeWindowID = window.id
        // Bring window to front
        if let nsWindow = nsWindows[window.id] {
            nsWindow.makeKeyAndOrderFront(nil)
        }
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
        // Close all windows
        for (_, nsWindow) in nsWindows {
            nsWindow.close()
        }
        nsWindows.removeAll()
        
        windows.forEach { $0.cleanup() }
        windows.removeAll()
    }
}
