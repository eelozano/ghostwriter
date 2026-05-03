import Cocoa
import Carbon

public struct ShortcutUtils {
    public static func carbonModifiers(from nsModifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbonMods: UInt32 = 0
        if nsModifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if nsModifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if nsModifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
        if nsModifiers.contains(.control) { carbonMods |= UInt32(controlKey) }
        return carbonMods
    }
}
