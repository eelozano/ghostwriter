import Cocoa
import Carbon

/// Utility functions for converting between modern Cocoa and legacy Carbon keyboard events.
///
/// This struct provides a bridge between the high-level NSEvent flag representations
/// and the low-level Carbon constants (e.g., cmdKey, optionKey) often required 
/// for global hotkey registration in macOS.
public struct ShortcutUtils {
    /// Converts SwiftUI/AppKit modifier flags into Carbon-compatible modifier constants.
    /// - Parameter nsModifiers: The modifier flags from an NSEvent.
    /// - Returns: A UInt32 bitmask of Carbon modifier keys.
    public static func carbonModifiers(from nsModifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbonMods: UInt32 = 0
        if nsModifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if nsModifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if nsModifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
        if nsModifiers.contains(.control) { carbonMods |= UInt32(controlKey) }
        return carbonMods
    }
}
