import Foundation

/// The root data structure for Ghostwriter, containing all user profiles.
struct GhostwriterData: Codable {
    /// A list of all profiles managed by the application.
    var profiles: [Profile]
}

/// Represents a logical grouping of categories and items, often tied to a specific context (e.g., "Work", "Personal").
struct Profile: Codable, Identifiable, Equatable {
    /// Unique identifier for the profile.
    var id: String
    /// The display name of the profile.
    var name: String
    /// Categories belonging to this profile.
    var categories: [Category]
}

/// A category within a profile that holds a list of items (e.g., "Email Addresses", "Snippets").
struct Category: Codable, Identifiable, Equatable {
    /// Unique identifier for the category.
    var id: String
    /// The display name of the category.
    var name: String
    /// The actual data items (strings) stored in this category.
    var items: [String]
    
    /// Initializes a new Category.
    /// - Parameters:
    ///   - id: The unique identifier. Defaults to a new UUID string.
    ///   - name: The name of the category.
    ///   - items: The list of items to initialize with.
    init(id: String = UUID().uuidString, name: String, items: [String]) {
        self.id = id
        self.name = name
        self.items = items
    }
    
    // Custom decoding: if an older JSON file has no 'id', generate one on the fly
    enum CodingKeys: String, CodingKey {
        case id, name, items
    }
    
    /// Custom decoding to handle legacy data formats or missing identifiers.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: DecodingError if required fields are missing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ARCHITECTURAL NOTE: Defensive identifier generation ensures that even legacy
        // data imported without IDs can be managed as Identifiable in SwiftUI views.
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        
        self.name = try container.decode(String.self, forKey: .name)
        self.items = try container.decode([String].self, forKey: .items)
    }
}
