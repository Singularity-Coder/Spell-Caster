import Foundation

/// Builds context from terminal state
class AIContextBuilder {
    private let paneViewModel: PaneViewModel
    private let toggles: ContextToggles
    private let redactor = SecretRedactor()
    
    init(paneViewModel: PaneViewModel, toggles: ContextToggles) {
        self.paneViewModel = paneViewModel
        self.toggles = toggles
    }
    
    func build() -> ContextSnapshot {
        var snapshot = paneViewModel.captureContext()
        
        // Apply toggles
        if !toggles.includeCurrentDirectory {
            snapshot.currentWorkingDirectory = nil
        }
        
        if !toggles.includeRecentOutput {
            snapshot.recentOutputLines = []
        }
        
        if !toggles.includeLastCommand {
            snapshot.lastCommand = nil
            snapshot.lastCommandExitStatus = nil
        }
        
        if !toggles.includeGitStatus {
            snapshot.gitBranch = nil
            snapshot.gitStatus = nil
        }
        
        if !toggles.includeEnvironment {
            snapshot.environmentVariables = nil
        }
        
        if !toggles.includeScrollback {
            snapshot.scrollbackLines = nil
        }
        
        // Redact secrets
        snapshot = redactor.redact(snapshot)
        
        return snapshot
    }
}
