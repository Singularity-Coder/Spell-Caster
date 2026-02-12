import SwiftUI

/// Main window layout with tab bar, terminal area, and AI sidebar
struct MainWindowView: View {
    @StateObject private var windowViewModel = WindowViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar at the top
            TabBarView(windowViewModel: windowViewModel)
            
            Divider()
            
            // Main content area
            HSplitView {
                // Terminal area
                SplitPaneView(windowViewModel: windowViewModel)
                    .frame(minWidth: 400)
                
                // AI Sidebar (toggleable)
                if windowViewModel.sidebarVisible {
                    if let activePane = windowViewModel.activePane {
                        AISidebarView(
                            session: windowViewModel.aiSession,
                            paneViewModel: activePane
                        )
                        .frame(minWidth: 300, idealWidth: 350, maxWidth: 500)
                        .transition(.move(edge: .trailing))
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // New Tab button
                Button(action: {
                    windowViewModel.createPane()
                }) {
                    Label("New Tab", systemImage: "plus")
                }
                .help("New Tab (⌘T)")
                
                Divider()
                
                // Split buttons
                Button(action: {
                    windowViewModel.createPane()
                }) {
                    Label("Split Horizontal", systemImage: "rectangle.split.2x1")
                }
                .help("Split Horizontally (⌘D)")
                
                Button(action: {
                    windowViewModel.createPane()
                }) {
                    Label("Split Vertical", systemImage: "rectangle.split.1x2")
                }
                .help("Split Vertically (⌘⇧D)")
                
                Divider()
                
                // Toggle sidebar button
                Button(action: {
                    withAnimation {
                        windowViewModel.toggleSidebar()
                    }
                }) {
                    Label("Toggle AI Sidebar", systemImage: windowViewModel.sidebarVisible ? "sidebar.right" : "sidebar.left")
                }
                .help("Toggle AI Sidebar (⌘⇧B)")
            }
        }
        .environmentObject(windowViewModel)
    }
}

#Preview {
    MainWindowView()
        .frame(width: 1200, height: 800)
}
