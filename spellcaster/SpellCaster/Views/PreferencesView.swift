import SwiftUI

/// Preferences window with tabs for General, Profiles, AI, and Advanced settings
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
        .frame(width: 600, height: 500)
    }
}

// MARK: - General Preferences

struct GeneralPreferencesView: View {
    @AppStorage("defaultShell") private var defaultShell: String = "/bin/zsh"
    @AppStorage("appearance") private var appearance: String = "system"
    @AppStorage("restoreSession") private var restoreSession: Bool = true
    
    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Restore previous session on launch", isOn: $restoreSession)
            }
            
            Section("Shell") {
                Picker("Default Shell:", selection: $defaultShell) {
                    Text("zsh (/bin/zsh)").tag("/bin/zsh")
                    Text("bash (/bin/bash)").tag("/bin/bash")
                    Text("fish (/usr/local/bin/fish)").tag("/usr/local/bin/fish")
                }
            }
            
            Section("Appearance") {
                Picker("Appearance:", selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }
        }
        .padding()
    }
}

// MARK: - Profiles Preferences

struct ProfilesPreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @State private var selectedProfileID: UUID?
    
    var body: some View {
        HSplitView {
            // Profile list
            VStack(alignment: .leading, spacing: 0) {
                List(selection: $selectedProfileID) {
                    ForEach(viewModel.profiles) { profile in
                        HStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .font(.body)
                                Text(profile.shellPath)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(profile.id)
                    }
                    .onDelete(perform: deleteProfile)
                }
                .listStyle(.sidebar)
                
                Divider()
                
                HStack {
                    Button(action: addProfile) {
                        Image(systemName: "plus")
                    }
                    
                    Button(action: { selectedProfileID = nil }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .disabled(selectedProfileID == nil)
                    
                    Spacer()
                }
                .padding(8)
            }
            .frame(width: 200)
            
            // Profile editor
            if let id = selectedProfileID,
               let profile = viewModel.profiles.first(where: { $0.id == id }) {
                SimpleProfileEditor(profile: profile, viewModel: viewModel)
            } else {
                VStack {
                    Text("Select a profile")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    var selectedProfile: Profile? {
        viewModel.profiles.first { $0.id == selectedProfileID }
    }
    
    func addProfile() {
        let newProfile = Profile(name: "New Profile")
        viewModel.saveProfile(newProfile)
        selectedProfileID = newProfile.id
    }
    
    func deleteProfile(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteProfile(viewModel.profiles[index])
        }
    }
}

struct SimpleProfileEditor: View {
    let profile: Profile
    let viewModel: PreferencesViewModel
    
    @State private var name: String
    @State private var shellPath: String
    @State private var fontName: String
    @State private var fontSize: Double
    @State private var cursorStyle: CursorStyleSetting
    @State private var cursorBlink: Bool
    
    init(profile: Profile, viewModel: PreferencesViewModel) {
        self.profile = profile
        self.viewModel = viewModel
        self._name = State(initialValue: profile.name)
        self._shellPath = State(initialValue: profile.shellPath)
        self._fontName = State(initialValue: profile.fontName)
        self._fontSize = State(initialValue: profile.fontSize)
        self._cursorStyle = State(initialValue: profile.cursorStyle)
        self._cursorBlink = State(initialValue: profile.cursorBlink)
    }
    
    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name:", text: $name)
            }
            
            Section("Shell") {
                TextField("Command:", text: $shellPath)
            }
            
            Section("Text") {
                Picker("Font:", selection: $fontName) {
                    Text("SF Mono").tag("SF Mono")
                    Text("Menlo").tag("Menlo")
                    Text("Monaco").tag("Monaco")
                    Text("Courier New").tag("Courier New")
                }
                
                Stepper("Size: \(Int(fontSize))", value: $fontSize, in: 9...24)
            }
            
            Section("Cursor") {
                Picker("Style:", selection: $cursorStyle) {
                    Text("Block").tag(CursorStyleSetting.block)
                    Text("Underline").tag(CursorStyleSetting.underline)
                    Text("Bar").tag(CursorStyleSetting.bar)
                }
                
                Toggle("Blinking cursor", isOn: $cursorBlink)
            }
            
            Button("Save Changes") {
                var updatedProfile = profile
                updatedProfile.name = name
                updatedProfile.shellPath = shellPath
                updatedProfile.fontName = fontName
                updatedProfile.fontSize = fontSize
                updatedProfile.cursorStyle = cursorStyle
                updatedProfile.cursorBlink = cursorBlink
                viewModel.saveProfile(updatedProfile)
            }
        }
        .padding()
    }
}

// MARK: - AI Preferences

struct AIPreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @State private var temperature: Double = 0.7
    
    var body: some View {
        Form {
            Section("API Configuration") {
                SecureField("OpenAI API Key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Button("Save API Key") {
                        viewModel.saveAPIKey()
                    }
                    
                    Button("Clear API Key") {
                        viewModel.deleteAPIKey()
                    }
                    .foregroundColor(.red)
                }
            }
            
            Section("Model Selection") {
                Picker("Model:", selection: .constant("gpt-4")) {
                    Text("GPT-4").tag("gpt-4")
                    Text("GPT-4 Turbo").tag("gpt-4-turbo")
                    Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                }
                
                VStack(alignment: .leading) {
                    Text("Temperature: \(String(format: "%.1f", temperature))")
                    Slider(value: $temperature, in: 0...2, step: 0.1)
                }
            }
            
            Section("Default Context") {
                Toggle("Include current directory", isOn: .constant(true))
                Toggle("Include recent output", isOn: .constant(true))
                Toggle("Include last command", isOn: .constant(true))
                Toggle("Include git status", isOn: .constant(true))
            }
            
            Section("Default Prompt Preset") {
                Picker("Preset:", selection: .constant("shell-assistant")) {
                    Text("Shell Assistant").tag("shell-assistant")
                    Text("DevOps").tag("devops")
                    Text("Python Expert").tag("python")
                    Text("Git Expert").tag("git")
                }
            }
        }
        .padding()
    }
}

// MARK: - Advanced Preferences

struct AdvancedPreferencesView: View {
    @AppStorage("scrollbackLines") private var scrollbackLines: Int = 10000
    @AppStorage("renderMode") private var renderMode: String = "metal"
    @AppStorage("shellIntegration") private var shellIntegration: Bool = true
    @AppStorage("logLevel") private var logLevel: String = "info"
    
    var body: some View {
        Form {
            Section("Scrollback") {
                Stepper("Buffer size: \(scrollbackLines) lines", value: $scrollbackLines, in: 1000...100000, step: 1000)
            }
            
            Section("Rendering") {
                Picker("Render Mode:", selection: $renderMode) {
                    Text("Metal (GPU)").tag("metal")
                    Text("Core Animation").tag("core-animation")
                    Text("Software").tag("software")
                }
            }
            
            Section("Shell Integration") {
                Toggle("Enable shell integration (cwd, git branch)", isOn: $shellIntegration)
                
                Text("Shell integration allows Spell Caster to detect the current working directory and git branch.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Logging") {
                Picker("Log Level:", selection: $logLevel) {
                    Text("Debug").tag("debug")
                    Text("Info").tag("info")
                    Text("Warning").tag("warning")
                    Text("Error").tag("error")
                }
            }
        }
        .padding()
    }
}

#Preview {
    PreferencesView()
}
