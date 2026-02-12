import SwiftUI

/// Tab bar view (placeholder for future implementation)
struct TabBarView: View {
    let panes: [PaneViewModel]
    @Binding var activePaneID: UUID?
    
    var body: some View {
        HStack {
            ForEach(panes) { pane in
                Button(action: {
                    activePaneID = pane.id
                }) {
                    Text("Terminal \(pane.id.uuidString.prefix(8))")
                }
                .buttonStyle(.bordered)
                .tint(activePaneID == pane.id ? .blue : .gray)
            }
        }
        .padding(4)
    }
}
