import XCTest
@testable import Ghostwriter

final class DataManagerTests: XCTestCase {
    
    var manager: DataManager!
    
    override func setUp() {
        super.setUp()
        // We create a fresh instance. Note: this might trigger loadData() from disk,
        // but we will override `data` immediately.
        manager = DataManager()
        
        let testProfile = Profile(id: "test-profile-1", name: "Test Profile", categories: [
            Category(id: "test-cat-1", name: "Test Category", items: ["Item A", "Item B", "Item C"])
        ])
        
        manager.data = GhostwriterData(profiles: [testProfile])
        manager.activeProfileId = "test-profile-1"
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    func testGetRandomItem() {
        let randomItem = manager.getRandomItem(for: "Test Category")
        XCTAssertNotNil(randomItem)
        XCTAssertTrue(["Item A", "Item B", "Item C"].contains(randomItem!))
    }
    
    func testGetRandomItemForInvalidCategory() {
        let randomItem = manager.getRandomItem(for: "Non Existent Category")
        XCTAssertNil(randomItem)
    }
    
    // Note: Methods like addCategory, addItem, etc. currently write to disk
    // via saveData(). In a fully testable architecture, we would inject a mock file manager
    // or a custom URL. For now, we are asserting basic read logic.
}
