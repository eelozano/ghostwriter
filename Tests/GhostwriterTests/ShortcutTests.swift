import XCTest
import Carbon
@testable import Ghostwriter

final class ShortcutTests: XCTestCase {
    func testCarbonModifierMapping() {
        // Test individual modifiers
        XCTAssertEqual(ShortcutUtils.carbonModifiers(from: .command), UInt32(cmdKey))
        XCTAssertEqual(ShortcutUtils.carbonModifiers(from: .shift), UInt32(shiftKey))
        XCTAssertEqual(ShortcutUtils.carbonModifiers(from: .option), UInt32(optionKey))
        XCTAssertEqual(ShortcutUtils.carbonModifiers(from: .control), UInt32(controlKey))
        
        // Test combinations
        XCTAssertEqual(ShortcutUtils.carbonModifiers(from: [.command, .shift]), UInt32(cmdKey | shiftKey))
        XCTAssertEqual(ShortcutUtils.carbonModifiers(from: [.option, .control]), UInt32(optionKey | controlKey))
        XCTAssertEqual(ShortcutUtils.carbonModifiers(from: [.command, .shift, .option, .control]), UInt32(cmdKey | shiftKey | optionKey | controlKey))
        
        // Test empty
        XCTAssertEqual(ShortcutUtils.carbonModifiers(from: []), 0)
    }
}
