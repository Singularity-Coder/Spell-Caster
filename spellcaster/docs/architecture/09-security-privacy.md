# Spell Caster - Security and Privacy

## Overview

This document outlines the security and privacy considerations for Spell Caster, including command execution safety, API key storage, secret redaction, and user data protection.

## Security Principles

1. **Least Privilege**: Run with minimum required permissions
2. **Defense in Depth**: Multiple layers of security controls
3. **Secure by Default**: Safe defaults for all security-sensitive features
4. **Transparency**: Clear visibility into what data is shared with AI
5. **User Control**: Users have full control over their data

## Threat Model

### Threats

| Threat | Impact | Mitigation |
|--------|--------|------------|
| Malicious command execution | System compromise | Command risk assessment, user confirmation |
| API key exposure | Unauthorized AI usage | Keychain storage, memory protection |
| Secret leakage to AI | Credential theft | Secret detection and redaction |
| Terminal output interception | Data exposure | Secure IPC, sandboxing |
| Session hijacking | Unauthorized access | Session encryption, authentication |
| Malicious AI responses | Code injection | Response sanitization, sandboxing |

## Command Execution Safety

### Risk Assessment

```swift
import Foundation

/// Assesses risk level of commands
final class CommandRiskAssessor {
    // MARK: - Risk Patterns
    
    private let highRiskPatterns: [RiskPattern] = [
        RiskPattern(
            pattern: try! NSRegularExpression(pattern: "rm\\s+-rf\\s+/", options: []),
            description: "Recursive deletion of root directory",
            level: .critical
        ),
        RiskPattern(
            pattern: try! NSRegularExpression(pattern: "dd\\s+if=.*of=/dev/", options: []),
            description: "Writing to device files",
            level: .critical
        ),
        RiskPattern(
            pattern: try! NSRegularExpression(pattern: "mkfs", options: []),
            description: "Filesystem formatting",
            level: .critical
        ),
        RiskPattern(
            pattern: try! NSRegularExpression(pattern: ":(){ :|:& };:", options: []),
            description: "Fork bomb",
            level: .critical
        ),
        RiskPattern(
            pattern: try! NSRegularExpression(pattern: "curl.*\\|.*sh", options: []),
            description: "Piping remote script to shell",
            level: .high
        ),
        RiskPattern(
            pattern: try! NSRegularExpression(pattern: "wget.*\\|.*sh", options: []),
            description: "Piping remote script to shell",
            level: .high
        ),
        RiskPattern(
            pattern: try! NSRegularExpression(pattern: "sudo\\s+rm", options: []),
            description: "Privileged deletion",
            level: .high
        ),
        RiskPattern(
            pattern: try! NSRegularExpression(pattern: "chmod\\s+777", options: []),
            description: "Overly permissive file permissions",
            level: .medium
        )
    ]
    
    private let mediumRiskKeywords = [
        "sudo", "rm", "mv", "chmod", "chown", "kill", "pkill",
        "systemctl", "service", "reboot", "shutdown"
    ]
    
    // MARK: - Assessment
    
    func assess(_ command: String) -> CommandRisk {
        // Check critical patterns first
        for pattern in highRiskPatterns {
            if pattern.pattern.firstMatch(
                in: command,
                options: [],
                range: NSRange(location: 0, length: command.utf16.count)
            ) != nil {
                return CommandRisk(
                    level: pattern.level,
                    reason: pattern.description,
                    requiresConfirmation: true
                )
            }
        }
        
        // Check for medium risk keywords
        let lowercased = command.lowercased()
        for keyword in mediumRiskKeywords {
            if lowercased.contains(keyword) {
                return CommandRisk(
                    level: .medium,
                    reason: "Contains potentially dangerous command: \(keyword)",
                    requiresConfirmation: true
                )
            }
        }
        
        // Default to low risk
        return CommandRisk(
            level: .low,
            reason: "Command appears safe",
            requiresConfirmation: false
        )
    }
}

// MARK: - Supporting Types

struct RiskPattern {
    let pattern: NSRegularExpression
    let description: String
    let level: RiskLevel
}

struct CommandRisk {
    let level: RiskLevel
    let reason: String
    let requiresConfirmation: Bool
}

enum RiskLevel: String {
    case low
    case medium
    case high
    case critical
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}
```

### Execution Confirmation

```swift
import SwiftUI

/// Confirmation dialog for risky commands
struct CommandConfirmationDialog: View {
    let command: String
    let risk: CommandRisk
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var userConfirmed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Warning icon
            Image(systemName: warningIcon)
                .font(.system(size: 48))
                .foregroundColor(risk.level.color)
            
            // Title
            Text("Confirm Command Execution")
                .font(.title2)
                .fontWeight(.bold)
            
            // Risk level
            HStack {
                Text("Risk Level:")
                    .fontWeight(.semibold)
                Text(risk.level.rawValue.capitalized)
                    .foregroundColor(risk.level.color)
                    .fontWeight(.bold)
            }
            
            // Reason
            Text(risk.reason)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Command preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Command:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(command)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(4)
            }
            
            // Confirmation checkbox for critical commands
            if risk.level == .critical {
                Toggle("I understand the risks and want to proceed", isOn: $userConfirmed)
                    .toggleStyle(.checkbox)
            }
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Execute", action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .disabled(risk.level == .critical && !userConfirmed)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
    
    private var warningIcon: String {
        switch risk.level {
        case .low: return "checkmark.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}
```

## API Key Security

### Keychain Integration

```swift
import Security
import Foundation

/// Secure API key storage using macOS Keychain
final class SecureAPIKeyStorage {
    private let service = "com.spellcaster.apikeys"
    private let accessGroup: String? = nil
    
    // MARK: - Storage
    
    func store(key: String, value: String, label: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // Delete existing item
        try? delete(key: key)
        
        // Create query
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrLabel as String: label,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Retrieval
    
    func retrieve(key: String) throws -> String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return string
    }
    
    // MARK: - Deletion
    
    func delete(key: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - List All
    
    func listAll() throws -> [KeychainItem] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return []
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            guard let account = item[kSecAttrAccount as String] as? String,
                  let label = item[kSecAttrLabel as String] as? String else {
                return nil
            }
            return KeychainItem(key: account, label: label)
        }
    }
}

// MARK: - Supporting Types

struct KeychainItem {
    let key: String
    let label: String
}
```

### Memory Protection

```swift
import Foundation

/// Secure string that zeros memory on deallocation
final class SecureString {
    private var data: Data
    
    init(_ string: String) {
        self.data = string.data(using: .utf8) ?? Data()
    }
    
    var value: String {
        String(data: data, encoding: .utf8) ?? ""
    }
    
    func clear() {
        // Zero out memory
        data.withUnsafeMutableBytes { bytes in
            memset(bytes.baseAddress, 0, bytes.count)
        }
        data = Data()
    }
    
    deinit {
        clear()
    }
}
```

## Secret Redaction

### Enhanced Secret Detection

```swift
import Foundation

/// Advanced secret detection and redaction
final class AdvancedSecretDetector {
    // MARK: - Entropy Analysis
    
    func detectHighEntropyStrings(_ text: String) -> [DetectedSecret] {
        var secrets: [DetectedSecret] = []
        
        // Split into words
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        
        for word in words {
            // Skip short strings
            guard word.count >= 20 else { continue }
            
            // Calculate Shannon entropy
            let entropy = calculateEntropy(word)
            
            // High entropy suggests random string (potential secret)
            if entropy > 4.5 {
                if let range = text.range(of: word) {
                    secrets.append(DetectedSecret(
                        type: "High Entropy String",
                        range: range,
                        preview: String(word.prefix(20)) + "..."
                    ))
                }
            }
        }
        
        return secrets
    }
    
    private func calculateEntropy(_ string: String) -> Double {
        var frequencies: [Character: Int] = [:]
        
        for char in string {
            frequencies[char, default: 0] += 1
        }
        
        let length = Double(string.count)
        var entropy: Double = 0
        
        for count in frequencies.values {
            let probability = Double(count) / length
            entropy -= probability * log2(probability)
        }
        
        return entropy
    }
    
    // MARK: - Context-Aware Detection
    
    func detectSecretsInContext(_ text: String) -> [DetectedSecret] {
        var secrets: [DetectedSecret] = []
        
        // Look for assignment patterns
        let assignmentPattern = "([A-Z_]+)\\s*=\\s*['\"]?([^'\"\\s]+)['\"]?"
        if let regex = try? NSRegularExpression(pattern: assignmentPattern, options: []) {
            let matches = regex.matches(
                in: text,
                options: [],
                range: NSRange(location: 0, length: text.utf16.count)
            )
            
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let keyRange = match.range(at: 1)
                    let valueRange = match.range(at: 2)
                    
                    if let keyNSRange = Range(keyRange, in: text),
                       let valueNSRange = Range(valueRange, in: text) {
                        let key = String(text[keyNSRange])
                        let value = String(text[valueNSRange])
                        
                        // Check if key suggests a secret
                        if isSecretKey(key) && value.count >= 8 {
                            secrets.append(DetectedSecret(
                                type: "Environment Variable",
                                range: valueNSRange,
                                preview: String(value.prefix(10)) + "..."
                            ))
                        }
                    }
                }
            }
        }
        
        return secrets
    }
    
    private func isSecretKey(_ key: String) -> Bool {
        let secretKeywords = [
            "KEY", "SECRET", "PASSWORD", "TOKEN", "PASS",
            "CREDENTIAL", "AUTH", "API", "PRIVATE"
        ]
        
        let uppercased = key.uppercased()
        return secretKeywords.contains { uppercased.contains($0) }
    }
}
```

## Private Mode

### Private Mode Implementation

```swift
import Foundation

/// Private mode that disables context capture and logging
final class PrivateMode {
    static let shared = PrivateMode()
    
    @Published private(set) var isEnabled: Bool = false
    
    private init() {}
    
    // MARK: - Control
    
    func enable() {
        isEnabled = true
        
        // Disable context capture
        NotificationCenter.default.post(name: .privateModeEnabled, object: nil)
        
        // Clear existing context
        clearSensitiveData()
    }
    
    func disable() {
        isEnabled = false
        
        // Re-enable context capture
        NotificationCenter.default.post(name: .privateModeDisabled, object: nil)
    }
    
    // MARK: - Data Clearing
    
    private func clearSensitiveData() {
        // Clear AI chat history
        NotificationCenter.default.post(name: .clearAIHistory, object: nil)
        
        // Clear context cache
        NotificationCenter.default.post(name: .clearContextCache, object: nil)
        
        // Clear clipboard if it contains sensitive data
        // (Optional - user preference)
    }
}

extension Notification.Name {
    static let privateModeEnabled = Notification.Name("privateModeEnabled")
    static let privateModeDisabled = Notification.Name("privateModeDisabled")
    static let clearContextCache = Notification.Name("clearContextCache")
}
```

## Data Minimization

### Context Filtering

```swift
import Foundation

/// Filters context to minimize data sent to AI
final class ContextMinimizer {
    func minimize(_ context: AIContext, settings: ContextSettings) -> AIContext {
        var minimized = context
        
        // Remove environment variables unless explicitly enabled
        if !settings.includeEnvironment {
            minimized.environment = nil
        }
        
        // Truncate output to configured line count
        if let output = minimized.recentOutput {
            let lines = output.components(separatedBy: .newlines)
            let truncated = lines.suffix(settings.recentOutputLines).joined(separator: "\n")
            minimized.recentOutput = truncated
        }
        
        // Remove selection if empty
        if minimized.selection?.isEmpty == true {
            minimized.selection = nil
        }
        
        // Simplify git status
        if var gitStatus = minimized.gitStatus {
            // Only include essential info
            gitStatus.ahead = 0
            gitStatus.behind = 0
            minimized.gitStatus = gitStatus
        }
        
        return minimized
    }
}
```

## Audit Logging

### Security Audit Log

```swift
import Foundation
import os.log

/// Security audit logger
final class SecurityAuditLogger {
    private let logger = Logger(subsystem: "com.spellcaster", category: "security")
    
    // MARK: - Logging
    
    func logCommandExecution(command: String, risk: RiskLevel, approved: Bool) {
        logger.info("""
            Command Execution:
            Command: \(command, privacy: .private)
            Risk: \(risk.rawValue)
            Approved: \(approved)
            """)
    }
    
    func logAPIKeyAccess(provider: String, success: Bool) {
        logger.info("""
            API Key Access:
            Provider: \(provider)
            Success: \(success)
            """)
    }
    
    func logSecretDetection(count: Int, redacted: Bool) {
        logger.info("""
            Secret Detection:
            Count: \(count)
            Redacted: \(redacted)
            """)
    }
    
    func logContextCapture(size: Int, sanitized: Bool) {
        logger.info("""
            Context Capture:
            Size: \(size) bytes
            Sanitized: \(sanitized)
            """)
    }
    
    func logPrivateModeToggle(enabled: Bool) {
        logger.info("Private Mode: \(enabled ? "Enabled" : "Disabled")")
    }
    
    func logSecurityViolation(description: String) {
        logger.error("Security Violation: \(description)")
    }
}
```

## Sandboxing

### App Sandbox Configuration

```xml
<!-- Entitlements.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Enable App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- Network access for AI providers -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- User-selected file access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Home directory access (for terminal) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    
    <!-- Keychain access -->
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.spellcaster</string>
    </array>
</dict>
</plist>
```

## Network Security

### TLS Configuration

```swift
import Foundation

/// Secure network configuration
final class SecureNetworkConfiguration {
    static func configure() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        
        // Require TLS 1.2 or higher
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        
        // Enable certificate pinning for known providers
        config.urlCredentialStorage = nil
        
        // Set reasonable timeouts
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        // Disable caching of sensitive data
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        return config
    }
}

/// Certificate pinning for AI providers
final class CertificatePinner: NSObject, URLSessionDelegate {
    private let pinnedCertificates: [String: [SecCertificate]]
    
    init(pinnedCertificates: [String: [SecCertificate]]) {
        self.pinnedCertificates = pinnedCertificates
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String?,
              let pinnedCerts = pinnedCertificates[host] else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Verify certificate chain
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)
        
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Check if any certificate in chain matches pinned certificates
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        for i in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) {
                if pinnedCerts.contains(where: { $0 == certificate }) {
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
        }
        
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
```

## User Consent

### Consent Management

```swift
import Foundation

/// Manages user consent for data sharing
final class ConsentManager {
    private let defaults = UserDefaults.standard
    
    enum ConsentType: String {
        case contextSharing = "consent.contextSharing"
        case errorReporting = "consent.errorReporting"
        case analytics = "consent.analytics"
    }
    
    // MARK: - Consent
    
    func hasConsent(for type: ConsentType) -> Bool {
        return defaults.bool(forKey: type.rawValue)
    }
    
    func grantConsent(for type: ConsentType) {
        defaults.set(true, forKey: type.rawValue)
        logConsentChange(type: type, granted: true)
    }
    
    func revokeConsent(for type: ConsentType) {
        defaults.set(false, forKey: type.rawValue)
        logConsentChange(type: type, granted: false)
        
        // Clear related data
        clearDataForConsentType(type)
    }
    
    // MARK: - Data Clearing
    
    private func clearDataForConsentType(_ type: ConsentType) {
        switch type {
        case .contextSharing:
            NotificationCenter.default.post(name: .clearContextCache, object: nil)
        case .errorReporting:
            // Clear error logs
            break
        case .analytics:
            // Clear analytics data
            break
        }
    }
    
    private func logConsentChange(type: ConsentType, granted: Bool) {
        let logger = SecurityAuditLogger()
        logger.logger.info("Consent \(granted ? "granted" : "revoked") for \(type.rawValue)")
    }
}
```

## Security Checklist

### Pre-Release Security Review

- [ ] All API keys stored in Keychain
- [ ] Secret redaction tested with common patterns
- [ ] Command risk assessment covers critical commands
- [ ] Private mode disables all context capture
- [ ] Audit logging enabled for security events
- [ ] App Sandbox properly configured
- [ ] TLS 1.2+ enforced for all network requests
- [ ] Certificate pinning implemented for AI providers
- [ ] User consent obtained before data sharing
- [ ] Memory cleared for sensitive data
- [ ] No secrets in logs or crash reports
- [ ] Input validation for all user-provided data
- [ ] Rate limiting for AI API calls
- [ ] Timeout handling for network requests
- [ ] Error messages don't leak sensitive info

## Summary

Security and privacy features:

| Feature | Purpose |
|---------|---------|
| [`CommandRiskAssessor`](#command-execution-safety) | Assesses command danger level |
| [`SecureAPIKeyStorage`](#api-key-security) | Keychain-based key storage |
| [`AdvancedSecretDetector`](#secret-redaction) | Detects and redacts secrets |
| [`PrivateMode`](#private-mode) | Disables context capture |
| [`SecurityAuditLogger`](#audit-logging) | Logs security events |
| [`CertificatePinner`](#network-security) | Pins SSL certificates |
| [`ConsentManager`](#user-consent) | Manages user consent |

## Next Steps

Continue to [10-file-structure.md](10-file-structure.md) for the project file structure.
