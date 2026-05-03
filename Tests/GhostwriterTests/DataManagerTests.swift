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
    
    // MARK: - Profile Mutation Tests
    
    func testAddProfile() {
        let initialCount = manager.data?.profiles.count ?? 0
        manager.addProfile(name: "New Profile")
        
        XCTAssertEqual(manager.data?.profiles.count, initialCount + 1)
        XCTAssertEqual(manager.data?.profiles.last?.name, "New Profile")
        XCTAssertEqual(manager.activeProfileId, manager.data?.profiles.last?.id)
    }
    
    func testRenameProfile() {
        manager.addProfile(name: "Old Name")
        let newProfileId = manager.data!.profiles.last!.id
        
        manager.renameProfile(id: newProfileId, newName: "Renamed Profile")
        
        let updatedProfile = manager.data?.profiles.first(where: { $0.id == newProfileId })
        XCTAssertEqual(updatedProfile?.name, "Renamed Profile")
    }
    
    func testDeleteProfile() {
        manager.addProfile(name: "To Delete")
        let newProfileId = manager.data!.profiles.last!.id
        let countBeforeDelete = manager.data!.profiles.count
        
        manager.deleteProfile(id: newProfileId)
        
        XCTAssertEqual(manager.data?.profiles.count, countBeforeDelete - 1)
        XCTAssertNil(manager.data?.profiles.first(where: { $0.id == newProfileId }))
    }
    
    func testDeleteActiveProfileUpdatesActiveProfileId() {
        // Setup a secondary profile
        manager.addProfile(name: "Secondary Profile")
        let secondaryId = manager.data!.profiles.last!.id
        
        // Ensure the active profile is the secondary one
        XCTAssertEqual(manager.activeProfileId, secondaryId)
        
        // Delete it
        manager.deleteProfile(id: secondaryId)
        
        // The active profile should fall back to the first available one ("test-profile-1" from setUp)
        XCTAssertEqual(manager.activeProfileId, "test-profile-1")
    }
}
