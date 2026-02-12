import SwiftUI

/// Command card with Insert/Run/Copy buttons
struct CommandCardView: View {
    let card: CommandCard
    let viewModel: AISidebarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Risk indicator
            HStack {
                Image(systemName: card.riskLevel.icon)
                    .foregroundColor(riskColor)
                Text(card.riskLevel.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(riskColor)
                Spacer()
                Text(card.type.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Command
            Text(card.command)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
            
            // Explanation
            if !card.explanation.isEmpty {
                Text(card.explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Warnings
            if !card.warnings.isEmpty {
                ForEach(card.warnings, id: \.self) { warning in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(warning)
                            .font(.caption)
                    }
                }
            }
            
            // Action buttons
            HStack {
                Button("Insert") {
                    viewModel.insertCommand(card)
                }
                .buttonStyle(.bordered)
                
                Button("Run") {
                    viewModel.runCommand(card)
                }
                .buttonStyle(.borderedProminent)
                .tint(card.riskLevel == .danger ? .red : .blue)
                
                Button("Copy") {
                    viewModel.copyCommand(card)
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(riskColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var riskColor: Color {
        switch card.riskLevel {
        case .safe: return .green
        case .caution: return .orange
        case .danger: return .red
        }
    }
}
