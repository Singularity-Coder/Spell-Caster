import Foundation
import Combine

/// Per-pane state management
class PaneViewModel: ObservableObject, Identifiable {
    // MARK: - Properties
    
    let id: UUID
    @Published var terminalState: TerminalState
    @Published var isActive: Bool = false
    @Published var isRunning: Bool = false
    
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
        setupTerminalStateObservers()
    }
    
    // MARK: - Setup
    
    private func setupPTYCallbacks() {
        ptyProcess.onOutput = { [weak self] data in
            self?.emulator.processData(data)
            self?.objectWillChange.send()
        }
        
        ptyProcess.onExit = { [weak self] exitCode in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.handleProcessExit(exitCode: exitCode)
            }
        }
    }
    
    private func setupTerminalStateObservers() {
        // Observe terminal state changes for redraw
        terminalState.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Process Management
    
    func launch() throws {
        guard !isRunning else { return }
        
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
        
        isRunning = true
    }
    
    func terminate() {
        ptyProcess.terminate()
        isRunning = false
    }
    
    // MARK: - Input
    
    func sendInput(_ data: Data) throws {
        try ptyProcess.write(data)
    }
    
    func sendInput(_ string: String) throws {
        try ptyProcess.write(string)
    }
    
    // MARK: - Resize
    
    func resize(rows: Int, columns: Int) throws {
        try ptyProcess.resize(rows: rows, columns: columns)
        terminalState.resize(rows: rows, columns: columns)
    }
    
    // MARK: - Signals
    
    func sendSignal(_ signal: Int32) throws {
        try ptyProcess.sendSignal(signal)
    }
    
    func sendInterrupt() throws {
        try sendSignal(SIGINT)
    }
    
    func sendSuspend() throws {
        try sendSignal(SIGTSTP)
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
    
    // MARK: - Selection
    
    func getSelection() -> String? {
        // TODO: Implement selection retrieval from terminal state
        return nil
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
        // Update shell integration with exit status
        terminalState.shellIntegration?.lastExitStatus = Int(exitCode)
        
        if profile.closeOnExit {
            // Notify that pane should close
            NotificationCenter.default.post(
                name: .paneDidExit,
                object: self,
                userInfo: ["exitCode": exitCode]
            )
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        terminate()
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let paneDidExit = Notification.Name("paneDidExit")
}
