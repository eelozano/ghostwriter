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
    var id: String
    var name: String
    var items: [String]
    
    init(id: String = UUID().uuidString, name: String, items: [String]) {
        self.id = id
        self.name = name
        self.items = items
    }
    
    // Custom decoding: if an older JSON file has no 'id', generate one on the fly
    enum CodingKeys: String, CodingKey {
        case id, name, items
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.name = try container.decode(String.self, forKey: .name)
        self.items = try container.decode([String].self, forKey: .items)
    }
}
