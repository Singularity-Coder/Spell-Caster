import Foundation

/// Profile CRUD operations
class ProfileManager {
    static let shared = ProfileManager()
    
    private let userDefaults = UserDefaults.standard
    private let profilesKey = "terminal-profiles"
    
    private init() {}
    
    // MARK: - Profile Management
    
    func loadProfiles() -> [Profile] {
        guard let data = userDefaults.data(forKey: profilesKey),
              let profiles = try? JSONDecoder().decode([Profile].self, from: data) else {
            // Return default profile if none exist
            return [.default]
        }
        
        return profiles.isEmpty ? [.default] : profiles
    }
    
    func saveProfile(_ profile: Profile) {
        var profiles = loadProfiles()
        
        // Update existing or add new
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        
        saveProfiles(profiles)
    }
    
    func deleteProfile(_ profile: Profile) {
        var profiles = loadProfiles()
        profiles.removeAll(where: { $0.id == profile.id })
        
        // Ensure at least one profile exists
        if profiles.isEmpty {
            profiles.append(.default)
        }
        
        saveProfiles(profiles)
    }
    
    func getProfile(byID id: UUID) -> Profile? {
        return loadProfiles().first(where: { $0.id == id })
    }
    
    func getDefaultProfile() -> Profile {
        return loadProfiles().first ?? .default
    }
    
    // MARK: - Private Methods
    
    private func saveProfiles(_ profiles: [Profile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            userDefaults.set(data, forKey: profilesKey)
        }
    }
}
