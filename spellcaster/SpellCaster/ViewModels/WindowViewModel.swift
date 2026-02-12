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
        
        // Create initial pane
        createPane()
    }
    
    // MARK: - Pane Management
    
    @discardableResult
    func createPane() -> PaneViewModel {
        let pane = PaneViewModel(profile: profile)
        panes.append(pane)
        activePaneID = pane.id
        
        // Launch the shell
        try? pane.launch()
        
        return pane
    }
    
    func closePane(_ pane: PaneViewModel) {
        pane.terminate()
        panes.removeAll(where: { $0.id == pane.id })
        
        // Select another pane if this was active
        if activePaneID == pane.id {
            activePaneID = panes.first?.id
        }
        
        // Close window if no panes left
        if panes.isEmpty {
            NotificationCenter.default.post(
                name: .windowShouldClose,
                object: self
            )
        }
    }
    
    func setActivePane(_ pane: PaneViewModel) {
        activePaneID = pane.id
        panes.forEach { $0.isActive = ($0.id == pane.id) }
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
}

// MARK: - Notifications

extension Notification.Name {
    static let windowShouldClose = Notification.Name("windowShouldClose")
}
