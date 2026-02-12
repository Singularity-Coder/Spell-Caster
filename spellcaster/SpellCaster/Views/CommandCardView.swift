import SwiftUI

/// Command card with Insert/Run/Copy buttons and multi-step support
struct CommandCardView: View {
    let card: CommandCard
    let viewModel: AISidebarViewModel
    
    @State private var isExpanded: Bool = false
    @State private var showConfirmation: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with risk indicator
            HStack {
                // Risk badge
                HStack(spacing: 4) {
                    Image(systemName: card.riskLevel.icon)
                        .font(.caption)
                    Text(card.riskLevel.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(riskColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(riskColor.opacity(0.15))
                .cornerRadius(4)
                
                // Command type
                Text(card.type.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(3)
                
                Spacer()
                
                // Expand/collapse for multi-step
                if card.type == .multiStep {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Command code block
            codeBlockView
            
            // Explanation
            if !card.explanation.isEmpty {
                Text(card.explanation)
                    .font(.callout)
                    .foregroundColor(.primary)
            }
            
            // Warnings
            if !card.warnings.isEmpty {
                warningsView
            }
            
            // Multi-step runbook
            if card.type == .multiStep && isExpanded {
                multiStepView
            }
            
            // Action buttons
            actionButtonsView
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(riskColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var codeBlockView: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line numbers gutter
            if card.type == .multiStep {
                let lines = card.command.components(separatedBy: "\n")
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(0..<lines.count, id: \.self) { index in
                        Text("\(index + 1)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(height: 18)
                    }
                }
                .padding(.trailing, 8)
                .padding(.vertical, 8)
            }
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(card.command)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
        }
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var warningsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(card.warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(card.riskLevel == .danger ? .red : .orange)
                        .font(.caption)
                    
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(card.riskLevel == .danger ? .red : .orange)
                }
            }
        }
        .padding(10)
        .background(
            (card.riskLevel == .danger ? Color.red : Color.orange).opacity(0.1)
        )
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var multiStepView: some View {
        let steps = card.command.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ForEach(0..<steps.count, id: \.self) { index in
                HStack {
                    Text("\(index + 1).")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text(steps[index])
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Insert button
            Button(action: {
                viewModel.insertCommand(card)
            }) {
                Label("Insert", systemImage: "text.insert")
                    .font(.callout)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            // Run button
            Button(action: {
                if card.riskLevel == .danger {
                    showConfirmation = true
                } else {
                    viewModel.runCommand(card)
                }
            }) {
                Label("Run", systemImage: "play.fill")
                    .font(.callout)
            }
            .buttonStyle(.borderedProminent)
            .tint(card.riskLevel == .danger ? .red : .green)
            .alert("Confirm Execution", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Run", role: .destructive) {
                    viewModel.runCommand(card)
                }
            } message: {
                Text("This command may be dangerous. Are you sure you want to run it?")
            }
            
            // Copy button
            Button(action: {
                viewModel.copyCommand(card)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.callout)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            
            Spacer()
        }
    }
    
    private var riskColor: Color {
        switch card.riskLevel {
        case .safe: return .green
        case .caution: return .orange
        case .danger: return .red
        }
    }
}

#Preview {
    let viewModel = AISidebarViewModel(
        session: AISession(),
        paneViewModel: PaneViewModel(profile: .default)
    )
    
    return VStack(spacing: 20) {
        CommandCardView(
            card: CommandCard(
                command: "ls -la",
                explanation: "List all files with detailed information",
                riskLevel: .safe
            ),
            viewModel: viewModel
        )
        
        CommandCardView(
            card: CommandCard(
                command: "sudo rm -rf /",
                explanation: "Remove all files recursively",
                warnings: ["This will delete all files", "Cannot be undone"],
                riskLevel: .danger
            ),
            viewModel: viewModel
        )
        
        CommandCardView(
            card: CommandCard(
                command: "git add .\ngit commit -m \"Update\"\ngit push",
                explanation: "Commit and push changes",
                riskLevel: .caution,
                type: .multiStep
            ),
            viewModel: viewModel
        )
    }
    .padding()
    .frame(width: 500)
}
