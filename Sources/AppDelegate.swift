import Cocoa
import SwiftUI
import Carbon
import Combine

/// The primary entry point for application-level lifecycle events.
/// Handles menu bar setup, global hotkey registration, and window coordination.
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var dataManager = DataManager.shared
    var commandPaletteWindow: NSWindow?
    var mainWindowController: MainWindowController?
    private var cancellables = Set<AnyCancellable>()
    
    var globalHotKeyRef: EventHotKeyRef?
    var hasInstalledGlobalHotkeyHandler = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMainMenu()
        
        // ARCHITECTURAL NOTE: Status items (menu bar icons) are the primary way users interact
        // with Ghostwriter without bringing a window to the foreground.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if let path = Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
               let image = NSImage(contentsOfFile: path) {
                image.size = NSSize(width: 20, height: 20)
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "👻 GW" // Fallback
            }
        }
        
        setupMenu()
        setupCommandPalette()
        setupGlobalHotkey()
        
        // INFORMATION FLOW: Observe profile changes to ensure the menu bar checkmark 
        // always reflects the current state, even if changed via the Command Palette or Editor.
        dataManager.$activeProfileId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupMenu()
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.addObserver(self, selector: #selector(setupGlobalHotkey), name: NSNotification.Name("UpdateGlobalHotkey"), object: nil)
        
        showMainWindow()
    }
    
    /// Configures the standard macOS application menu (About, Preferences, Quit, etc.)
    func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // ... (standard menu items)
        
        NSApplication.shared.mainMenu = mainMenu
    }
    
    @objc func showMainWindow() {
        if mainWindowController == nil {
            mainWindowController = MainWindowController(dataManager: dataManager)
        }
        mainWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func setupMenu() {
        let menu = NSMenu()
        
        // Profile Submenu
        let profileMenuItem = NSMenuItem(title: "Active Profile", action: nil, keyEquivalent: "")
        let profileMenu = NSMenu()
        
        if let data = dataManager.data, !data.profiles.isEmpty {
            for profile in data.profiles {
                let item = NSMenuItem(title: profile.name, action: #selector(selectProfile(_:)), keyEquivalent: "")
                item.representedObject = profile.id
                item.state = (dataManager.activeProfileId == profile.id) ? .on : .off
                profileMenu.addItem(item)
            }
        } else {
            let emptyItem = NSMenuItem(title: "No Profiles Available", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            profileMenu.addItem(emptyItem)
        }
        
        profileMenuItem.submenu = profileMenu
        menu.addItem(profileMenuItem)
        menu.addItem(NSMenuItem.separator())
        

        

        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit Ghostwriter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func selectProfile(_ sender: NSMenuItem) {
        guard let profileId = sender.representedObject as? String else { return }
        dataManager.activeProfileId = profileId
        // Update menu states
        setupMenu()
        // Notify palette to refresh if needed
        NotificationCenter.default.post(name: NSNotification.Name("ProfileChanged"), object: nil)
    }
    
    @objc func importData() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        NSApp.activate(ignoringOtherApps: true)
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                if let profiles = self.dataManager.data?.profiles, !profiles.isEmpty {
                    let alert = NSAlert()
                    alert.messageText = "Import Data"
                    alert.informativeText = "Would you like to merge the imported data with your existing profiles, or completely overwrite them?"
                    alert.addButton(withTitle: "Merge")
                    alert.addButton(withTitle: "Overwrite")
                    alert.addButton(withTitle: "Cancel")
                    
                    let result = alert.runModal()
                    if result == .alertFirstButtonReturn {
                        self.dataManager.importData(from: url, overwrite: false)
                        self.setupMenu()
                    } else if result == .alertSecondButtonReturn {
                        self.dataManager.importData(from: url, overwrite: true)
                        self.setupMenu()
                    }
                } else {
                    self.dataManager.importData(from: url, overwrite: true)
                    self.setupMenu()
                }
            }
        }
    }
    
    @objc func downloadTemplate() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "ghostwriter-template.json"
        
        NSApp.activate(ignoringOtherApps: true)
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                self.dataManager.generateTemplate(at: url)
            }
        }
    }
    
    @objc func exportData() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "ghostwriter-export.json"
        
        NSApp.activate(ignoringOtherApps: true)
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                self.dataManager.exportData(to: url)
            }
        }
    }
    
    func setupCommandPalette() {
        // Will implement in CommandPalette.swift
        commandPaletteWindow = CommandPaletteWindow.create(dataManager: dataManager)
    }
    
    /// Registers the global system-wide hotkey using the Carbon framework.
    /// This allows the Command Palette to be summoned even when Ghostwriter is in the background.
    @objc func setupGlobalHotkey() {
        if let ref = globalHotKeyRef {
            UnregisterEventHotKey(ref)
            globalHotKeyRef = nil
        }
        
        let defaults = UserDefaults.standard
        let savedKeyCode = defaults.object(forKey: "shortcutKeyCode") as? UInt32
        let savedModifiers = defaults.object(forKey: "shortcutModifiers") as? UInt32
        
        // Fallback defaults: Cmd + Shift + P
        let keyCode = savedKeyCode ?? 35 
        let modifierFlags = savedModifiers ?? UInt32(cmdKey | shiftKey)
        
        let hotKeyID = EventHotKeyID(signature: 0x47575254, id: 1) // 'GWRT'
        
        // ARCHITECTURAL NOTE: Carbon's RegisterEventHotKey is a legacy C API but remains 
        // the standard way to implement system-wide hotkeys on macOS without Accessibility permissions.
        let status = RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetApplicationEventTarget(), 0, &globalHotKeyRef)
        if status != noErr {
            print("Failed to register global hotkey")
        }
        
        if !hasInstalledGlobalHotkeyHandler {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            
            // INFORMATION FLOW: When the hotkey is pressed, we dispatch a notification on the main thread
            // to toggle the palette window.
            let handler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("TogglePaletteShortcut"), object: nil)
                }
                return noErr
            }
            
            InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
            NotificationCenter.default.addObserver(self, selector: #selector(showCommandPaletteMenu), name: NSNotification.Name("TogglePaletteShortcut"), object: nil)
            
            hasInstalledGlobalHotkeyHandler = true
        }
    }
    
    @objc func showCommandPaletteMenu() {
        toggleCommandPalette()
    }
    
    func toggleCommandPalette() {
        guard let window = commandPaletteWindow else { return }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            // Refresh data in case of changes
            NotificationCenter.default.post(name: NSNotification.Name("PaletteWillShow"), object: nil)
            window.makeKeyAndOrderFront(nil)
            // Focus search field (handled in SwiftUI)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }
}
