import SwiftUI

/// Tab bar view with tab management
struct TabBarView: View {
    @ObservedObject var windowViewModel: WindowViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // Tab items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(windowViewModel.panes) { pane in
                        TabItemView(
                            pane: pane,
                            isActive: windowViewModel.activePaneID == pane.id,
                            onSelect: {
                                windowViewModel.setActivePane(pane)
                            },
                            onClose: {
                                windowViewModel.closePane(pane)
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // New tab button
            Button(action: {
                windowViewModel.createPane()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("New Tab")
            .padding(.trailing, 8)
        }
        .frame(height: 32)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// Individual tab item
struct TabItemView: View {
    let pane: PaneViewModel
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 4) {
            // Tab title
            Text(tabTitle)
                .font(.system(size: 11))
                .lineLimit(1)
                .foregroundColor(isActive ? .primary : .secondary)
            
            // Close button
            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 14, height: 14)
                .help("Close Tab")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var tabTitle: String {
        // Try to get title from shell integration (cwd)
        if let cwd = pane.terminalState.shellIntegration?.currentWorkingDirectory {
            let url = URL(fileURLWithPath: cwd)
            return url.lastPathComponent
        }
        
        // Fallback to shell type
        let shellPath = pane.terminalState.shellIntegration?.shellType?.rawValue ?? "Shell"
        return shellPath.capitalized
    }
}

#Preview {
    TabBarView(windowViewModel: WindowViewModel())
        .frame(width: 600)
}
