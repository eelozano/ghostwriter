import Cocoa

// ARCHITECTURAL NOTE: Ghostwriter uses a manual NSApplication setup instead of 
// @main or @UIApplicationMain to ensure fine-grained control over the application 
// lifecycle and delegate retention, which is critical for status-item only apps.

let app = NSApplication.shared
let delegate = AppDelegate()

// ARCHITECTURAL NOTE: NSApplication.delegate is a weak reference. We must retain it 
// strongly in this top-level scope or the instance will be deallocated immediately, 
// causing the menu bar icon to disappear.
var strongDelegate: AppDelegate? = delegate
app.delegate = strongDelegate
app.run()
