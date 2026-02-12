import Foundation
import Combine

/// Preferences logic
class PreferencesViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published var profiles: [Profile] = []
    @Published var selectedProfile: Profile?
    @Published var apiKey: String = ""
    
    private let profileManager = ProfileManager.shared
    private let keychainService = KeychainService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadProfiles()
        loadAPIKey()
    }
    
    // MARK: - Profile Management
    
    func loadProfiles() {
        profiles = profileManager.loadProfiles()
        if selectedProfile == nil {
            selectedProfile = profiles.first
        }
    }
    
    func saveProfile(_ profile: Profile) {
        profileManager.saveProfile(profile)
        loadProfiles()
    }
    
    func deleteProfile(_ profile: Profile) {
        profileManager.deleteProfile(profile)
        loadProfiles()
    }
    
    func duplicateProfile(_ profile: Profile) {
        var newProfile = profile
        newProfile.id = UUID()
        newProfile.name = "\(profile.name) Copy"
        saveProfile(newProfile)
    }
    
    // MARK: - API Key Management
    
    func loadAPIKey() {
        if let key = keychainService.getAPIKey(for: "openai") {
            apiKey = key
        }
    }
    
    func saveAPIKey() {
        keychainService.saveAPIKey(apiKey, for: "openai")
    }
    
    func deleteAPIKey() {
        keychainService.deleteAPIKey(for: "openai")
        apiKey = ""
    }
}
