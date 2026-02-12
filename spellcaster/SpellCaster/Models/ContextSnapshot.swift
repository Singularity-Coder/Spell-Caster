import Foundation

/// Terminal context snapshot for AI
struct ContextSnapshot: Codable {
    // MARK: - Working Directory
    
    var currentWorkingDirectory: String?
    
    // MARK: - Shell Information
    
    var shellType: ShellType?
    var shellVersion: String?
    
    // MARK: - Recent Output
    
    var recentOutputLines: [String]
    var outputLineCount: Int
    
    // MARK: - Last Command
    
    var lastCommand: String?
    var lastCommandExitStatus: Int?
    var lastCommandTimestamp: Date?
    
    // MARK: - Git Information
    
    var gitBranch: String?
    var gitStatus: String?
    var gitRemote: String?
    
    // MARK: - Selection
    
    var selectedText: String?
    
    // MARK: - Environment
    
    var environmentVariables: [String: String]?
    
    // MARK: - Scrollback
    
    var scrollbackLines: [String]?
    
    // MARK: - Security
    
    var redacted: Bool
    var redactionCount: Int
    
    // MARK: - Metadata
    
    var captureTimestamp: Date
    var terminalSize: (rows: Int, columns: Int)
    
    init(
        currentWorkingDirectory: String? = nil,
        shellType: ShellType? = nil,
        shellVersion: String? = nil,
        recentOutputLines: [String] = [],
        outputLineCount: Int = 0,
        lastCommand: String? = nil,
        lastCommandExitStatus: Int? = nil,
        lastCommandTimestamp: Date? = nil,
        gitBranch: String? = nil,
        gitStatus: String? = nil,
        gitRemote: String? = nil,
        selectedText: String? = nil,
        environmentVariables: [String: String]? = nil,
        scrollbackLines: [String]? = nil,
        redacted: Bool = false,
        redactionCount: Int = 0,
        captureTimestamp: Date = Date(),
        terminalSize: (rows: Int, columns: Int) = (24, 80)
    ) {
        self.currentWorkingDirectory = currentWorkingDirectory
        self.shellType = shellType
        self.shellVersion = shellVersion
        self.recentOutputLines = recentOutputLines
        self.outputLineCount = outputLineCount
        self.lastCommand = lastCommand
        self.lastCommandExitStatus = lastCommandExitStatus
        self.lastCommandTimestamp = lastCommandTimestamp
        self.gitBranch = gitBranch
        self.gitStatus = gitStatus
        self.gitRemote = gitRemote
        self.selectedText = selectedText
        self.environmentVariables = environmentVariables
        self.scrollbackLines = scrollbackLines
        self.redacted = redacted
        self.redactionCount = redactionCount
        self.captureTimestamp = captureTimestamp
        self.terminalSize = terminalSize
    }
    
    /// Format context as a string for AI prompt
    func formatForPrompt() -> String {
        var parts: [String] = []
        
        // Working directory
        if let cwd = currentWorkingDirectory {
            parts.append("Current Directory: \(cwd)")
        }
        
        // Shell info
        if let shell = shellType {
            var shellInfo = "Shell: \(shell.rawValue)"
            if let version = shellVersion {
                shellInfo += " (\(version))"
            }
            parts.append(shellInfo)
        }
        
        // Terminal size
        parts.append("Terminal Size: \(terminalSize.rows)x\(terminalSize.columns)")
        
        // Last command
        if let cmd = lastCommand {
            var cmdInfo = "Last Command: \(cmd)"
            if let exitStatus = lastCommandExitStatus {
                cmdInfo += " (exit: \(exitStatus))"
            }
            parts.append(cmdInfo)
        }
        
        // Git info
        if let branch = gitBranch {
            parts.append("Git Branch: \(branch)")
        }
        if let status = gitStatus, !status.isEmpty {
            parts.append("Git Status:\n\(status)")
        }
        
        // Recent output
        if !recentOutputLines.isEmpty {
            parts.append("Recent Output (\(outputLineCount) lines):")
            parts.append(recentOutputLines.joined(separator: "\n"))
        }
        
        // Selection
        if let selection = selectedText, !selection.isEmpty {
            parts.append("Selected Text:\n\(selection)")
        }
        
        // Scrollback
        if let scrollback = scrollbackLines, !scrollback.isEmpty {
            parts.append("Scrollback History (\(scrollback.count) lines):")
            parts.append(scrollback.joined(separator: "\n"))
        }
        
        // Redaction notice
        if redacted && redactionCount > 0 {
            parts.append("[Note: \(redactionCount) potential secret(s) were redacted from this context]")
        }
        
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Shell Type

enum ShellType: String, Codable {
    case bash
    case zsh
    case fish
    case sh
    case ksh
    case tcsh
    case unknown
    
    /// Detect shell type from path
    static func detect(from path: String) -> ShellType {
        let name = (path as NSString).lastPathComponent
        switch name {
        case "bash": return .bash
        case "zsh": return .zsh
        case "fish": return .fish
        case "sh": return .sh
        case "ksh": return .ksh
        case "tcsh": return .tcsh
        default: return .unknown
        }
    }
}
