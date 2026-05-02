import Cocoa
import SwiftUI

class CommandPaletteWindow: NSPanel {
    static func create(dataManager: DataManager) -> CommandPaletteWindow {
        let view = CommandPaletteView(dataManager: dataManager)
        let hostingController = NSHostingController(rootView: view)
        
        let window = CommandPaletteWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.center()
        window.isFloatingPanel = true
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        
        return window
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    // Hide when clicking outside
    override func resignKey() {
        super.resignKey()
        self.orderOut(nil)
    }
}

struct CommandPaletteView: View {
    @ObservedObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool
    
    let publisher = NotificationCenter.default.publisher(for: NSNotification.Name("PaletteWillShow"))
    
    var filteredCategories: [Category] {
        guard let data = dataManager.data,
              let activeProfileId = dataManager.activeProfileId,
              let profile = data.profiles.first(where: { $0.id == activeProfileId }) else {
            return []
        }
        
        if searchText.isEmpty {
            return profile.categories
        }
        
        // Simple case-insensitive subsequence match for fuzzy search
        return profile.categories.filter { category in
            let catName = category.name.lowercased()
            let search = searchText.lowercased()
            
            var searchIndex = search.startIndex
            for char in catName {
                if searchIndex == search.endIndex { break }
                if char == search[searchIndex] {
                    searchIndex = search.index(after: searchIndex)
                }
            }
            return searchIndex == search.endIndex
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search data types...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 20))
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _ in
                        selectedIndex = 0
                    }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Results List
            ScrollViewReader { proxy in
                List(0..<filteredCategories.count, id: \.self) { index in
                    let category = filteredCategories[index]
                    HStack {
                        Text(category.name)
                            .font(.system(size: 16))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(index == selectedIndex ? Color.accentColor : Color.clear)
                    .foregroundColor(index == selectedIndex ? .white : .primary)
                    .cornerRadius(6)
                    .onTapGesture {
                        executeSelection(at: index)
                    }
                }
                .listStyle(PlainListStyle())
                .onChange(of: selectedIndex) { newIndex in
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 450, height: 350)
        .background(VisualEffectView().edgesIgnoringSafeArea(.all))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onReceive(publisher) { _ in
            self.searchText = ""
            self.selectedIndex = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isSearchFocused = true
            }
        }
        // Handle Keyboard Navigation
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 125 { // Down Arrow
                    if selectedIndex < filteredCategories.count - 1 {
                        selectedIndex += 1
                    }
                    return nil
                } else if event.keyCode == 126 { // Up Arrow
                    if selectedIndex > 0 {
                        selectedIndex -= 1
                    }
                    return nil
                } else if event.keyCode == 36 { // Enter
                    if !filteredCategories.isEmpty {
                        executeSelection(at: selectedIndex)
                    }
                    return nil
                } else if event.keyCode == 53 { // Escape
                    NSApp.keyWindow?.orderOut(nil)
                    return nil
                }
                return event
            }
        }
    }
    
    private func executeSelection(at index: Int) {
        let category = filteredCategories[index]
        if let randomItem = dataManager.getRandomItem(for: category.name) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(randomItem, forType: .string)
            
            // Audio Feedback
            NSSound(named: "Pop")?.play()
            
            // Hide window
            NSApp.keyWindow?.orderOut(nil)
            
            // Optional: Show "Ghost" notification
            // A simple way is to use NSUserNotification, but it's deprecated.
            // For a minimal approach, the sound is often enough, or we could flash a HUD.
        }
    }
}

// Helper view for macOS blur effect
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .popover
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
