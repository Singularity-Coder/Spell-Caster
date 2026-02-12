import SwiftUI

/// Context inspector panel (placeholder for future implementation)
struct ContextInspectorView: View {
    let context: ContextSnapshot
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Terminal Context")
                    .font(.headline)
                
                if let cwd = context.currentWorkingDirectory {
                    LabeledContent("Directory", value: cwd)
                }
                
                if let shell = context.shellType {
                    LabeledContent("Shell", value: shell.rawValue)
                }
                
                if let branch = context.gitBranch {
                    LabeledContent("Git Branch", value: branch)
                }
                
                if let lastCommand = context.lastCommand {
                    VStack(alignment: .leading) {
                        Text("Last Command")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lastCommand)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .padding()
        }
    }
}
