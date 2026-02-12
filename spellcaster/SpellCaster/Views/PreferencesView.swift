import SwiftUI

/// Preferences window
struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    
    var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            ProfilesPreferencesView(viewModel: viewModel)
                .tabItem {
                    Label("Profiles", systemImage: "list.bullet")
                }
            
            AIPreferencesView(viewModel: viewModel)
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
            
            AdvancedPreferencesView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 600, height: 400)
    }
}

struct GeneralPreferencesView: View {
    var body: some View {
        Form {
            Text("General preferences")
        }
        .padding()
    }
}

struct ProfilesPreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    
    var body: some View {
        Form {
            Text("Profile management")
        }
        .padding()
    }
}

struct AIPreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    
    var body: some View {
        Form {
            Section("API Configuration") {
                SecureField("OpenAI API Key", text: $viewModel.apiKey)
                Button("Save API Key") {
                    viewModel.saveAPIKey()
                }
            }
            
            Section("Model Selection") {
                Picker("Model", selection: .constant("gpt-4")) {
                    Text("GPT-4").tag("gpt-4")
                    Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                }
            }
        }
        .padding()
    }
}

struct AdvancedPreferencesView: View {
    var body: some View {
        Form {
            Text("Advanced settings")
        }
        .padding()
    }
}
