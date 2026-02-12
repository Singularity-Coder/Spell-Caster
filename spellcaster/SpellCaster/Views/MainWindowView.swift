import SwiftUI

/// Main window layout with terminal area and AI sidebar
struct MainWindowView: View {
    @StateObject private var paneViewModel: PaneViewModel
    @StateObject private var aiSession: AISession
    @State private var sidebarVisible: Bool = true
    
    init() {
        let profile = ProfileManager.shared.getDefaultProfile()
        _paneViewModel = StateObject(wrappedValue: PaneViewModel(profile: profile))
        _aiSession = StateObject(wrappedValue: AISession(
            selectedModel: profile.aiModel,
            systemPromptPreset: profile.aiSystemPromptPreset
        ))
    }
    
    var body: some View {
        HSplitView {
            // Terminal area
            TerminalViewRepresentable(paneViewModel: paneViewModel)
                .frame(minWidth: 400)
            
            // AI Sidebar (toggleable)
            if sidebarVisible {
                AISidebarView(session: aiSession, paneViewModel: paneViewModel)
                    .frame(minWidth: 300, idealWidth: 350, maxWidth: 500)
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Toggle sidebar button
                Button(action: {
                    withAnimation {
                        sidebarVisible.toggle()
                    }
                }) {
                    Label("Toggle AI Sidebar", systemImage: sidebarVisible ? "sidebar.right" : "sidebar.left")
                }
                .help("Toggle AI Sidebar")
            }
        }
        .onAppear {
            // Launch the shell when view appears
            paneViewModel.launchLazily()
        }
    }
}

#Preview {
    MainWindowView()
        .frame(width: 1200, height: 800)
}
