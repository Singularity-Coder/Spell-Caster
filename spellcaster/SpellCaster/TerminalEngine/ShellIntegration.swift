import Foundation

/// Shell integration state tracking and utilities
class ShellIntegration {
    /// Generate shell integration script path for a given shell
    static func scriptPath(for shell: ShellType) -> String? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        
        let scriptName: String
        switch shell {
        case .bash:
            scriptName = "spellcaster-bash.sh"
        case .zsh:
            scriptName = "spellcaster-zsh.sh"
        case .fish:
            // Fish integration would be different
            return nil
        default:
            return nil
        }
        
        return "\(resourcePath)/ShellIntegration/\(scriptName)"
    }
    
    /// Generate environment variables for shell integration
    static func environmentVariables(for shell: ShellType) -> [String: String] {
        var env: [String: String] = [:]
        
        // Set integration marker
        env["SPELLCASTER_SHELL_INTEGRATION"] = "1"
        
        // Set shell-specific variables
        switch shell {
        case .bash:
            if let scriptPath = scriptPath(for: .bash) {
                env["PROMPT_COMMAND"] = "source \(scriptPath); ${PROMPT_COMMAND}"
            }
        case .zsh:
            if let scriptPath = scriptPath(for: .zsh) {
                env["ZDOTDIR"] = (scriptPath as NSString).deletingLastPathComponent
            }
        default:
            break
        }
        
        return env
    }
    
    /// Parse shell integration OSC sequence
    static func parseOSC(_ sequence: String) -> ShellIntegrationEvent? {
        // Format: OSC 1337 ; key=value ST
        let parts = sequence.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        
        let key = String(parts[0])
        let value = String(parts[1])
        
        switch key {
        case "CurrentDir":
            return .currentDirectory(value)
        case "RemoteHost":
            return .remoteHost(value)
        case "ShellIntegrationVersion":
            return .version(value)
        case "PromptStart":
            return .promptStart
        case "PromptEnd":
            return .promptEnd
        case "CommandStart":
            return .commandStart
        case "CommandEnd":
            if let exitStatus = Int(value) {
                return .commandEnd(exitStatus)
            }
        default:
            break
        }
        
        return nil
    }
}

// MARK: - Shell Integration Event

enum ShellIntegrationEvent {
    case currentDirectory(String)
    case remoteHost(String)
    case version(String)
    case promptStart
    case promptEnd
    case commandStart
    case commandEnd(Int)
}
