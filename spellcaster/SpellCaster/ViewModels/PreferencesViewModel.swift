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
        if profiles.isEmpty {
            // Create default profile if none exist
            let defaultProfile = Profile.default
            profileManager.saveProfile(defaultProfile)
            profiles = [defaultProfile]
        }
        if selectedProfile == nil {
            selectedProfile = profiles.first
        }
    }
    
    func saveProfile(_ profile: Profile) {
        profileManager.saveProfile(profile)
        loadProfiles()
        
        // Update selected profile if it was modified
        if selectedProfile?.id == profile.id {
            selectedProfile = profile
        }
    }
    
    func deleteProfile(_ profile: Profile) {
        profileManager.deleteProfile(profile)
        loadProfiles()
        
        // Clear selection if deleted profile was selected
        if selectedProfile?.id == profile.id {
            selectedProfile = profiles.first
        }
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
