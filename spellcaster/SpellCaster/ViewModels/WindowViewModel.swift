import Foundation
import Combine
import SwiftUI

/// Per-window state management
class WindowViewModel: ObservableObject, Identifiable {
    // MARK: - Properties
    
    let id: UUID
    @Published var panes: [PaneViewModel] = []
    @Published var activePaneID: UUID?
    @Published var sidebarVisible: Bool = true
    @Published var aiSession: AISession
    
    private let profile: Profile
    private var cancellables = Set<AnyCancellable>()
    
    var activePane: PaneViewModel? {
        guard let id = activePaneID else { return panes.first }
        return panes.first(where: { $0.id == id })
    }
    
    // MARK: - Initialization
    
    init(profile: Profile = .default) {
        self.id = UUID()
        self.profile = profile
        self.aiSession = AISession(
            selectedModel: profile.aiModel,
            systemPromptPreset: profile.aiSystemPromptPreset
        )
        
        // Create initial pane (don't launch yet - launch lazily)
        createPane()
        
        // Listen for pane exit notifications
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .paneDidExit)
            .sink { [weak self] notification in
                if let pane = notification.object as? PaneViewModel {
                    self?.handlePaneExit(pane: pane, exitCode: notification.userInfo?["exitCode"] as? Int32 ?? 0)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .windowShouldClose)
            .sink { [weak self] notification in
                if let window = notification.object as? WindowViewModel, window.id == self?.id {
                    // Handle window close request
                }
            }
            .store(in: &cancellables)
    }
    
    private func handlePaneExit(pane: PaneViewModel, exitCode: Int32) {
        if profile.closeOnExit {
            closePane(pane)
        }
    }
    
    // MARK: - Pane Management
    
    @discardableResult
    func createPane() -> PaneViewModel {
        let pane = PaneViewModel(profile: profile)
        panes.append(pane)
        setActivePane(pane)
        
        // Launch the shell lazily (on first access)
        pane.launchLazily()
        
        return pane
    }
    
    func addPane() {
        createPane()
    }
    
    func closePane(_ pane: PaneViewModel) {
        pane.terminate()
        panes.removeAll(where: { $0.id == pane.id })
        
        // Select another pane if this was active
        if activePaneID == pane.id {
            activePaneID = panes.first?.id
        }
        
        // Mark remaining panes as inactive
        panes.forEach { $0.isActive = false }
        activePane?.isActive = true
        
        // Close window if no panes left
        if panes.isEmpty {
            NotificationCenter.default.post(
                name: .windowShouldClose,
                object: self
            )
        }
    }
    
    func removePane(id: UUID) {
        if let pane = panes.first(where: { $0.id == id }) {
            closePane(pane)
        }
    }
    
    func setActivePane(_ pane: PaneViewModel) {
        activePaneID = pane.id
        panes.forEach { $0.isActive = ($0.id == pane.id) }
    }
    
    func setActivePane(id: UUID) {
        if let pane = panes.first(where: { $0.id == id }) {
            setActivePane(pane)
        }
    }
    
    // MARK: - Split Pane Management
    
    func splitPane(direction: SplitDirection) {
        // For MVP, just create a new pane
        // Future: Implement actual split view
        createPane()
    }
    
    func splitPaneHorizontally() {
        createPane()
    }
    
    func splitPaneVertically() {
        createPane()
    }
    
    // MARK: - Sidebar Management
    
    func toggleSidebar() {
        sidebarVisible.toggle()
    }
    
    // MARK: - Terminal Operations
    
    func clearScrollback() {
        activePane?.clearScrollback()
    }
    
    func resetTerminal() {
        activePane?.reset()
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        panes.forEach { $0.terminate() }
        panes.removeAll()
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - Split Direction

enum SplitDirection {
    case horizontal
    case vertical
}

// MARK: - Notifications

extension Notification.Name {
    static let windowShouldClose = Notification.Name("windowShouldClose")
}
