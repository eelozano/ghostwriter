import Cocoa
import SwiftUI
import Carbon
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var dataManager = DataManager.shared
    var commandPaletteWindow: NSWindow?
    var mainWindowController: MainWindowController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMainMenu()
        
        // Create the status item
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
        
        // Observe profile changes from other parts of the app to sync the menu bar checkmarks
        dataManager.$activeProfileId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupMenu()
            }
            .store(in: &cancellables)
        
        showMainWindow()
    }
    
    func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // Application Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About Ghostwriter", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showMainWindow), keyEquivalent: ","))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Hide Ghostwriter", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem({
            let item = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            item.keyEquivalentModifierMask = [.command, .option]
            return item
        }())
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Ghostwriter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(NSMenuItem(title: "Import Data...", action: #selector(importData), keyEquivalent: "i"))
        fileMenu.addItem(NSMenuItem(title: "Download Template...", action: #selector(downloadTemplate), keyEquivalent: ""))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // Edit Menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        // Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(NSMenuItem(title: "Main Window", action: #selector(showMainWindow), keyEquivalent: "1"))
        windowMenu.addItem(NSMenuItem(title: "Command Palette", action: #selector(showCommandPaletteMenu), keyEquivalent: "p"))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
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
                self.dataManager.importData(from: url)
                self.setupMenu()
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
    
    func setupCommandPalette() {
        // Will implement in CommandPalette.swift
        commandPaletteWindow = CommandPaletteWindow.create(dataManager: dataManager)
    }
    
    func setupGlobalHotkey() {
        // Switch to Carbon Event HotKeys for more robust global registration 
        // that often bypasses the strict Accessibility requirement bugs.
        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID(signature: 0x47575254, id: 1) // 'GWRT'
        
        // kVK_ANSI_P is 35. cmdKey is 0x0100, shiftKey is 0x0200
        let modifierFlags = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 35 
        
        let status = RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            print("Failed to register global hotkey")
        }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            // Post a notification because this C-function closure cannot capture 'self'
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("TogglePaletteShortcut"), object: nil)
            }
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
        
        // Listen for the notification
        NotificationCenter.default.addObserver(self, selector: #selector(showCommandPaletteMenu), name: NSNotification.Name("TogglePaletteShortcut"), object: nil)
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
}
