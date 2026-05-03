import XCTest
@testable import Ghostwriter

final class ModelsTests: XCTestCase {
    
    func testCategoryInitialization() {
        let category = Category(name: "TestCategory", items: ["Item1", "Item2"])
        XCTAssertEqual(category.name, "TestCategory")
        XCTAssertEqual(category.items, ["Item1", "Item2"])
        XCTAssertFalse(category.id.isEmpty)
    }
    
    func testCategoryDecodingWithId() throws {
        let json = """
        {
            "id": "1234-5678",
            "name": "DecodedCategory",
            "items": ["A", "B"]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let category = try decoder.decode(Category.self, from: json)
        
        XCTAssertEqual(category.id, "1234-5678")
        XCTAssertEqual(category.name, "DecodedCategory")
        XCTAssertEqual(category.items, ["A", "B"])
    }
    
    func testCategoryDecodingWithoutId() throws {
        let json = """
        {
            "name": "LegacyCategory",
            "items": ["Old1"]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let category = try decoder.decode(Category.self, from: json)
        
        XCTAssertFalse(category.id.isEmpty) // ID should be auto-generated
        XCTAssertEqual(category.name, "LegacyCategory")
        XCTAssertEqual(category.items, ["Old1"])
    }
    
    func testGhostwriterDataDecoding() throws {
        let json = """
        {
            "profiles": [
                {
                    "id": "profile1",
                    "name": "Profile 1",
                    "categories": [
                        {
                            "id": "cat1",
                            "name": "Category 1",
                            "items": ["Item 1"]
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let data = try decoder.decode(GhostwriterData.self, from: json)
        
        XCTAssertEqual(data.profiles.count, 1)
        XCTAssertEqual(data.profiles[0].id, "profile1")
        XCTAssertEqual(data.profiles[0].categories.count, 1)
        XCTAssertEqual(data.profiles[0].categories[0].id, "cat1")
    }
}
