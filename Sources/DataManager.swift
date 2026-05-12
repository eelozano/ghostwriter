import Foundation
import AppKit

/// The central data authority for the application.
/// Manages persistence, profile/category mutations, and reactive state updates via `@Published` properties.
class DataManager: ObservableObject {
    /// Shared singleton instance.
    static let shared = DataManager()
    
    @Published var data: GhostwriterData?
    @Published var activeProfileId: String?
    
    private let fileManager = FileManager.default
    private let dataFileName = "data.json"
    
    /// The root directory for application data in Application Support.
    private var dataDirectoryURL: URL? {
        // ARCHITECTURAL NOTE: Storing in Application Support is the standard macOS pattern
        // for persistent app state that isn't a user document.
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Ghostwriter")
    }
    
    private var dataFileURL: URL? {
        dataDirectoryURL?.appendingPathComponent(dataFileName)
    }
    
    init() {
        createDataDirectoryIfNeeded()
        loadData()
    }
    
    private func createDataDirectoryIfNeeded() {
        guard let dirURL = dataDirectoryURL else { return }
        if !fileManager.fileExists(atPath: dirURL.path) {
            do {
                try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating data directory: \(error)")
            }
        }
    }
    
    /// Loads Ghostwriter data from the local JSON file.
    /// If the file does not exist, initializes an empty data set.
    func loadData() {
        guard let fileURL = dataFileURL else { return }
        
        // INFORMATION FLOW: Check for existence first to avoid throw/catch overhead for new users.
        if !fileManager.fileExists(atPath: fileURL.path) {
            self.data = GhostwriterData(profiles: [])
            return
        }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            self.data = try decoder.decode(GhostwriterData.self, from: fileData)
            
            if activeProfileId == nil, let firstProfile = self.data?.profiles.first {
                activeProfileId = firstProfile.id
            }
        } catch {
            print("Error loading data: \(error)")
        }
    }
    
    /// Persists the current state to the local JSON file.
    /// This should be called after any mutation to the `data` property.
    func saveData() {
        guard let fileURL = dataFileURL, let data = self.data else { return }
        
        // ARCHITECTURAL NOTE: We use pretty-printing to make the data file human-readable,
        // which facilitates manual debugging or version control if the user stores it in a repo.
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let fileData = try encoder.encode(data)
            try fileData.write(to: fileURL)
        } catch {
            print("Error saving data: \(error)")
        }
    }
    
    /// Imports data from an external JSON file.
    /// - Parameters:
    ///   - url: The location of the JSON file to import.
    ///   - overwrite: If true, replaces all current data. If false, performs an additive merge.
    func importData(from url: URL, overwrite: Bool) {
        do {
            let fileData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedData = try decoder.decode(GhostwriterData.self, from: fileData)
            
            if overwrite || self.data == nil {
                // INFORMATION FLOW: Direct replacement of the root data structure.
                self.data = importedData
                if let first = importedData.profiles.first {
                    self.activeProfileId = first.id
                }
            } else {
                // ARCHITECTURAL NOTE: Additive Merge Strategy
                // This logic attempts to merge imported profiles and categories into the existing set
                // based on name matching, preventing duplicate entries for items.
                for importedProfile in importedData.profiles {
                    if let localProfileIndex = self.data?.profiles.firstIndex(where: { $0.name == importedProfile.name }) {
                        // Profile match found: Merge categories within this profile.
                        for importedCategory in importedProfile.categories {
                            if let localCategoryIndex = self.data?.profiles[localProfileIndex].categories.firstIndex(where: { $0.name == importedCategory.name }) {
                                // Category match found: Merge items, filtering out existing ones.
                                let existingItems = self.data?.profiles[localProfileIndex].categories[localCategoryIndex].items ?? []
                                let newItems = importedCategory.items.filter { !existingItems.contains($0) }
                                self.data?.profiles[localProfileIndex].categories[localCategoryIndex].items.append(contentsOf: newItems)
                            } else {
                                // New category in existing profile: Append it.
                                self.data?.profiles[localProfileIndex].categories.append(importedCategory)
                            }
                        }
                    } else {
                        // New profile: Append with a fresh UUID to ensure uniqueness.
                        var newProfile = importedProfile
                        newProfile.id = UUID().uuidString
                        self.data?.profiles.append(newProfile)
                    }
                }
            }
            saveData()
        } catch {
            // FIXME: Decouple logic from UI. The DataManager should throw errors or use a 
            // result handler instead of presenting an NSAlert directly, which limits 
            // its use in non-UI contexts (like CLI tools or background tasks).
            print("Error importing data: \(error)")
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Import Failed"
                alert.informativeText = "The selected file is not a valid Ghostwriter JSON format. Error: \(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    func generateTemplate(at url: URL) {
        let templateData = GhostwriterData(profiles: [
            Profile(id: "template", name: "Sample Profile", categories: [
                Category(name: "Sample Email", items: ["test@example.com", "user@example.com"])
            ])
        ])
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let fileData = try encoder.encode(templateData)
            try fileData.write(to: url)
        } catch {
            print("Error saving template: \(error)")
        }
    }
    
    func exportData(to url: URL) {
        guard let data = self.data else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let fileData = try encoder.encode(data)
            try fileData.write(to: url)
        } catch {
            print("Error exporting data: \(error)")
        }
    }
    
    /// Retrieves a random item from the specified category in the active profile.
    /// - Parameter categoryName: The name of the category to search.
    /// - Returns: A random string item if found, otherwise nil.
    func getRandomItem(for categoryName: String) -> String? {
        // INFORMATION FLOW: Validates existence of data, active profile, and the category name.
        guard let data = self.data,
              let activeProfileId = self.activeProfileId,
              let profile = data.profiles.first(where: { $0.id == activeProfileId }),
              let category = profile.categories.first(where: { $0.name == categoryName }) else {
            return nil
        }
        
        return category.items.randomElement()
    }
    
    // MARK: - Profile Mutations
    
    func addProfile(name: String) {
        let newProfile = Profile(id: UUID().uuidString, name: name, categories: [])
        if data == nil {
            data = GhostwriterData(profiles: [newProfile])
        } else {
            data?.profiles.append(newProfile)
        }
        activeProfileId = newProfile.id
        saveData()
    }
    
    func renameProfile(id: String, newName: String) {
        guard let index = data?.profiles.firstIndex(where: { $0.id == id }) else { return }
        data?.profiles[index].name = newName
        saveData()
    }
    
    func deleteProfile(id: String) {
        guard let index = data?.profiles.firstIndex(where: { $0.id == id }) else { return }
        data?.profiles.remove(at: index)
        
        if activeProfileId == id {
            activeProfileId = data?.profiles.first?.id
        }
        saveData()
    }
    
    // MARK: - Category Mutations
    
    func renameCategory(profileId: String, categoryId: String, newName: String) {
        guard let pi = data?.profiles.firstIndex(where: { $0.id == profileId }),
              let ci = data?.profiles[pi].categories.firstIndex(where: { $0.id == categoryId }) else { return }
        data?.profiles[pi].categories[ci].name = newName
        saveData()
    }
    
    func deleteCategory(profileId: String, categoryId: String) {
        guard let pi = data?.profiles.firstIndex(where: { $0.id == profileId }) else { return }
        data?.profiles[pi].categories.removeAll(where: { $0.id == categoryId })
        saveData()
    }
    
    func addItem(_ item: String, profileId: String, categoryId: String) {
        guard let pi = data?.profiles.firstIndex(where: { $0.id == profileId }),
              let ci = data?.profiles[pi].categories.firstIndex(where: { $0.id == categoryId }) else { return }
        data?.profiles[pi].categories[ci].items.append(item)
        saveData()
    }
    
    func addItems(_ items: [String], profileId: String, categoryId: String) {
        guard let pi = data?.profiles.firstIndex(where: { $0.id == profileId }),
              let ci = data?.profiles[pi].categories.firstIndex(where: { $0.id == categoryId }) else { return }
        data?.profiles[pi].categories[ci].items.append(contentsOf: items)
        saveData()
    }
    
    func deleteItem(at itemIndex: Int, profileId: String, categoryId: String) {
        guard let pi = data?.profiles.firstIndex(where: { $0.id == profileId }),
              let ci = data?.profiles[pi].categories.firstIndex(where: { $0.id == categoryId }),
              let items = data?.profiles[pi].categories[ci].items,
              itemIndex < items.count else { return }
        data?.profiles[pi].categories[ci].items.remove(at: itemIndex)
        saveData()
    }
    
    func addCategory(profileId: String, name: String) {
        guard let pi = data?.profiles.firstIndex(where: { $0.id == profileId }) else { return }
        let newCategory = Category(name: name, items: [])
        data?.profiles[pi].categories.append(newCategory)
        saveData()
    }
    
    func copyCategory(categoryId: String, fromProfileId: String, toProfileId: String, includeItems: Bool) {
        guard let sourceProfile = data?.profiles.first(where: { $0.id == fromProfileId }),
              let sourceCategory = sourceProfile.categories.first(where: { $0.id == categoryId }),
              let pi = data?.profiles.firstIndex(where: { $0.id == toProfileId }) else { return }
        let copiedCategory = Category(
            name: sourceCategory.name,
            items: includeItems ? sourceCategory.items : []
        )
        data?.profiles[pi].categories.append(copiedCategory)
        saveData()
    }
}
