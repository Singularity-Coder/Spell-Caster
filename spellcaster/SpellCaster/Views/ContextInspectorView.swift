import SwiftUI

/// Context inspector panel showing what context will be sent to AI
struct ContextInspectorView: View {
    let context: ContextSnapshot
    @Binding var toggles: ContextToggles
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
                
                Text("Terminal Context")
                    .font(.headline)
                
                Spacer()
                
                // Toggle all
                Button(action: toggleAll) {
                    Text(isExpanded ? "Collapse" : "Expand")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            // Toggle switches
            HStack(spacing: 16) {
                ToggleContextChip(
                    icon: "folder",
                    label: "CWD",
                    isOn: $toggles.includeCurrentDirectory
                )
                
                ToggleContextChip(
                    icon: "doc.text",
                    label: "Output",
                    isOn: $toggles.includeRecentOutput
                )
                
                ToggleContextChip(
                    icon: "terminal",
                    label: "Last Cmd",
                    isOn: $toggles.includeLastCommand
                )
                
                ToggleContextChip(
                    icon: "arrow.triangle.branch",
                    label: "Git",
                    isOn: $toggles.includeGitStatus
                )
            }
            
            // Expanded details
            if isExpanded {
                expandedDetailsView
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private var expandedDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            // Current working directory
            if let cwd = context.currentWorkingDirectory {
                contextItemView(
                    icon: "folder.fill",
                    label: "Directory",
                    value: cwd,
                    isEnabled: toggles.includeCurrentDirectory
                )
            }
            
            // Shell type
            if let shell = context.shellType {
                contextItemView(
                    icon: "terminal",
                    label: "Shell",
                    value: shell.rawValue,
                    isEnabled: true
                )
            }
            
            // Git branch
            if let branch = context.gitBranch {
                contextItemView(
                    icon: "arrow.triangle.branch",
                    label: "Git Branch",
                    value: branch,
                    isEnabled: toggles.includeGitStatus
                )
            }
            
            // Last command
            if let lastCommand = context.lastCommand {
                contextItemView(
                    icon: "chevron.left.square",
                    label: "Last Command",
                    value: lastCommand,
                    isEnabled: toggles.includeLastCommand
                )
            }
            
            // Exit status
            if let exitStatus = context.lastCommandExitStatus {
                HStack {
                    Image(systemName: exitStatus == 0 ? "checkmark.circle" : "xmark.circle")
                        .foregroundColor(exitStatus == 0 ? .green : .red)
                    
                    Text("Exit Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(exitStatus)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(exitStatus == 0 ? .green : .red)
                }
            }
            
            // Recent output preview
            if !context.recentOutputLines.isEmpty && toggles.includeRecentOutput {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.secondary)
                        Text("Recent Output (\(context.outputLineCount) lines)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(previewOutput)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(5)
                    }
                    .frame(maxHeight: 80)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                }
            }
            
            // Redacted items count
            if context.redactedItemsCount > 0 {
                HStack {
                    Image(systemName: "eye.slash.fill")
                        .foregroundColor(.orange)
                    Text("\(context.redactedItemsCount) items redacted for security")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Terminal size
            HStack {
                Image(systemName: "rectangle")
                    .foregroundColor(.secondary)
                Text("Terminal:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(context.terminalSize.columns)x\(context.terminalSize.rows)")
                    .font(.system(.caption, design: .monospaced))
            }
        }
    }
    
    private func contextItemView(icon: String, label: String, value: String, isEnabled: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .accentColor : .secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(isEnabled ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }
    
    private var previewOutput: String {
        context.recentOutputLines
            .suffix(10)
            .joined(separator: "\n")
    }
    
    private func toggleAll() {
        withAnimation {
            isExpanded.toggle()
        }
    }
}

/// Toggle chip for context items
struct ToggleContextChip: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isOn ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundColor(isOn ? .accentColor : .secondary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let context = ContextSnapshot(
        currentWorkingDirectory: "/Users/test/project",
        shellType: .zsh,
        recentOutputLines: ["total 24", "drwxr-xr-x  5 test  staff   160 Feb 12 10:00 .", "drwxr-xr-x  3 test  staff    96 Feb 12 09:00 ..", "-rw-r--r--  1 test  staff  1024 Feb 12 10:00 README.md"],
        outputLineCount: 156,
        lastCommand: "ls -la",
        lastCommandExitStatus: 0,
        gitBranch: "main",
        terminalSize: TerminalSize(rows: 24, columns: 80)
    )
    
    return ContextInspectorView(
        context: context,
        toggles: .constant(ContextToggles())
    )
    .frame(width: 350)
}
