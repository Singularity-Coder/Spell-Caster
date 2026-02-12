import Foundation
import Combine

/// Per-pane state management
class PaneViewModel: ObservableObject, Identifiable {
    // MARK: - Properties
    
    let id: UUID
    @Published var terminalState: TerminalState
    @Published var isActive: Bool = false
    
    private let ptyProcess: PTYProcess
    private let emulator: TerminalEmulator
    private let profile: Profile
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(profile: Profile, rows: Int = 24, columns: Int = 80) {
        self.id = UUID()
        self.profile = profile
        self.ptyProcess = PTYProcess()
        self.emulator = TerminalEmulator(rows: rows, columns: columns)
        self.terminalState = emulator.state
        
        setupPTYCallbacks()
    }
    
    // MARK: - Setup
    
    private func setupPTYCallbacks() {
        ptyProcess.onOutput = { [weak self] data in
            self?.emulator.processData(data)
        }
        
        ptyProcess.onExit = { [weak self] exitCode in
            self?.handleProcessExit(exitCode: exitCode)
        }
    }
    
    // MARK: - Process Management
    
    func launch() throws {
        let shellType = ShellType.detect(from: profile.shellPath)
        var env = profile.environmentVariables
        
        // Add shell integration
        let integrationEnv = ShellIntegration.environmentVariables(for: shellType)
        env.merge(integrationEnv) { _, new in new }
        
        try ptyProcess.launch(
            command: profile.shellPath,
            arguments: profile.shellArguments,
            environment: env,
            workingDirectory: profile.workingDirectory,
            rows: terminalState.activeGrid.rows,
            columns: terminalState.activeGrid.columns
        )
    }
    
    func terminate() {
        ptyProcess.terminate()
    }
    
    func sendInput(_ data: Data) throws {
        try ptyProcess.write(data)
    }
    
    func sendInput(_ string: String) throws {
        try ptyProcess.write(string)
    }
    
    func resize(rows: Int, columns: Int) throws {
        try ptyProcess.resize(rows: rows, columns: columns)
        terminalState.resize(rows: rows, columns: columns)
    }
    
    func sendSignal(_ signal: Int32) throws {
        try ptyProcess.sendSignal(signal)
    }
    
    // MARK: - Terminal Operations
    
    func clear() {
        terminalState.clear()
    }
    
    func clearScrollback() {
        terminalState.clearScrollback()
    }
    
    func reset() {
        terminalState.reset()
    }
    
    // MARK: - Context Capture
    
    func captureContext() -> ContextSnapshot {
        let grid = terminalState.activeGrid
        
        // Get recent output (last 50 lines)
        var recentLines: [String] = []
        let startRow = max(0, grid.rows - 50)
        for row in startRow..<grid.rows {
            let line = grid.getRow(row)
            let text = line.map { String(Character($0.character)) }.joined()
            recentLines.append(text)
        }
        
        return ContextSnapshot(
            currentWorkingDirectory: terminalState.shellIntegration?.currentWorkingDirectory,
            shellType: ShellType.detect(from: profile.shellPath),
            recentOutputLines: recentLines,
            outputLineCount: recentLines.count,
            lastCommand: terminalState.shellIntegration?.currentCommand,
            lastCommandExitStatus: terminalState.shellIntegration?.lastExitStatus,
            gitBranch: terminalState.shellIntegration?.gitBranch,
            terminalSize: TerminalSize(rows: grid.rows, columns: grid.columns)
        )
    }
    
    // MARK: - Private Methods
    
    private func handleProcessExit(exitCode: Int32) {
        if profile.closeOnExit {
            // Notify that pane should close
            NotificationCenter.default.post(
                name: .paneDidExit,
                object: self,
                userInfo: ["exitCode": exitCode]
            )
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let paneDidExit = Notification.Name("paneDidExit")
}
