import Foundation

struct GhostwriterData: Codable {
    var profiles: [Profile]
}

struct Profile: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var categories: [Category]
}

struct Category: Codable, Identifiable, Equatable {
    var id: String { name } // Using name as ID for simplicity
    var name: String
    var items: [String]
}
