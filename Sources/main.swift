import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
// NSApplication.delegate is a weak reference, so we must retain it strongly here or else the menu bar icon immediately disappears!
var strongDelegate: AppDelegate? = delegate
app.delegate = strongDelegate
app.run()
