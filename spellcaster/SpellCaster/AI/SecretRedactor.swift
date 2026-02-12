import Foundation

/// Detects and redacts secrets from terminal context
class SecretRedactor {
    private let patterns: [SecretPattern]
    
    init() {
        self.patterns = [
            // API Keys
            SecretPattern(name: "API Key", regex: #"[A-Za-z0-9_-]{32,}"#),
            SecretPattern(name: "AWS Access Key", regex: #"AKIA[0-9A-Z]{16}"#),
            SecretPattern(name: "GitHub Token", regex: #"ghp_[A-Za-z0-9]{36}"#),
            SecretPattern(name: "OpenAI API Key", regex: #"sk-[A-Za-z0-9]{48}"#),
            
            // Passwords
            SecretPattern(name: "Password", regex: #"password[=:]\s*[^\s]+"#, caseInsensitive: true),
            SecretPattern(name: "Token", regex: #"token[=:]\s*[^\s]+"#, caseInsensitive: true),
            
            // Private Keys
            SecretPattern(name: "Private Key", regex: #"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"#),
            
            // JWT Tokens
            SecretPattern(name: "JWT", regex: #"eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"#),
            
            // Connection Strings
            SecretPattern(name: "Connection String", regex: #"(?:mongodb|postgres|mysql)://[^@]+@[^\s]+"#),
        ]
    }
    
    func redact(_ snapshot: ContextSnapshot) -> ContextSnapshot {
        var redacted = snapshot
        var redactionCount = 0
        
        // Redact recent output
        redacted.recentOutputLines = snapshot.recentOutputLines.map { line in
            var redactedLine = line
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern.regex, options: pattern.options) {
                    let range = NSRange(redactedLine.startIndex..., in: redactedLine)
                    let matches = regex.matches(in: redactedLine, range: range)
                    
                    if !matches.isEmpty {
                        redactionCount += matches.count
                        redactedLine = regex.stringByReplacingMatches(
                            in: redactedLine,
                            range: range,
                            withTemplate: "[REDACTED:\(pattern.name)]"
                        )
                    }
                }
            }
            return redactedLine
        }
        
        // Redact last command
        if let command = snapshot.lastCommand {
            var redactedCommand = command
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern.regex, options: pattern.options) {
                    let range = NSRange(redactedCommand.startIndex..., in: redactedCommand)
                    let matches = regex.matches(in: redactedCommand, range: range)
                    
                    if !matches.isEmpty {
                        redactionCount += matches.count
                        redactedCommand = regex.stringByReplacingMatches(
                            in: redactedCommand,
                            range: range,
                            withTemplate: "[REDACTED:\(pattern.name)]"
                        )
                    }
                }
            }
            redacted.lastCommand = redactedCommand
        }
        
        // Redact environment variables
        if var env = snapshot.environmentVariables {
            let sensitiveKeys = ["API_KEY", "SECRET", "PASSWORD", "TOKEN", "PRIVATE_KEY"]
            for key in env.keys {
                if sensitiveKeys.contains(where: { key.uppercased().contains($0) }) {
                    env[key] = "[REDACTED]"
                    redactionCount += 1
                }
            }
            redacted.environmentVariables = env
        }
        
        // Redact scrollback
        if let scrollback = snapshot.scrollbackLines {
            redacted.scrollbackLines = scrollback.map { line in
                var redactedLine = line
                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern.regex, options: pattern.options) {
                        let range = NSRange(redactedLine.startIndex..., in: redactedLine)
                        let matches = regex.matches(in: redactedLine, range: range)
                        
                        if !matches.isEmpty {
                            redactionCount += matches.count
                            redactedLine = regex.stringByReplacingMatches(
                                in: redactedLine,
                                range: range,
                                withTemplate: "[REDACTED:\(pattern.name)]"
                            )
                        }
                    }
                }
                return redactedLine
            }
        }
        
        redacted.redacted = redactionCount > 0
        redacted.redactionCount = redactionCount
        
        return redacted
    }
}

// MARK: - Secret Pattern

private struct SecretPattern {
    let name: String
    let regex: String
    let caseInsensitive: Bool
    
    var options: NSRegularExpression.Options {
        return caseInsensitive ? [.caseInsensitive] : []
    }
    
    init(name: String, regex: String, caseInsensitive: Bool = false) {
        self.name = name
        self.regex = regex
        self.caseInsensitive = caseInsensitive
    }
}
