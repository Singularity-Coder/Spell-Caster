import Foundation

/// AI command proposal with Insert/Run/Copy actions
struct CommandCard: Identifiable, Codable {
    let id: UUID
    let command: String
    let explanation: String
    let warnings: [String]
    let riskLevel: RiskLevel
    let type: CommandType
    var executed: Bool
    
    init(
        id: UUID = UUID(),
        command: String,
        explanation: String,
        warnings: [String] = [],
        riskLevel: RiskLevel = .safe,
        type: CommandType = .single,
        executed: Bool = false
    ) {
        self.id = id
        self.command = command
        self.explanation = explanation
        self.warnings = warnings
        self.riskLevel = riskLevel
        self.type = type
        self.executed = executed
    }
}

// MARK: - Risk Level

enum RiskLevel: String, Codable {
    case safe       // No destructive operations
    case caution    // Modifies files or system state
    case danger     // Potentially destructive (rm, dd, etc.)
    
    var color: String {
        switch self {
        case .safe: return "green"
        case .caution: return "yellow"
        case .danger: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .safe: return "checkmark.circle"
        case .caution: return "exclamationmark.triangle"
        case .danger: return "xmark.octagon"
        }
    }
}

// MARK: - Command Type

enum CommandType: String, Codable {
    case single     // Single command
    case multiStep  // Multiple commands to be executed in sequence
    case script     // Shell script
    
    var description: String {
        switch self {
        case .single: return "Single Command"
        case .multiStep: return "Multi-Step"
        case .script: return "Script"
        }
    }
}
