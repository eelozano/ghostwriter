import Cocoa
import SwiftUI

class MainWindowController: NSWindowController {
    convenience init(dataManager: DataManager) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.title = "Ghostwriter"
        
        let contentView = MainContentView(dataManager: dataManager)
        window.contentView = NSHostingView(rootView: contentView)
        
        self.init(window: window)
    }
}

struct MainContentView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedProfileId: String?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Profiles")) {
                    if let data = dataManager.data {
                        ForEach(data.profiles) { profile in
                            NavigationLink(
                                destination: ProfileDetailView(dataManager: dataManager, profile: profile),
                                tag: profile.id,
                                selection: $selectedProfileId
                            ) {
                                HStack {
                                    Text(profile.name)
                                        .fontWeight(dataManager.activeProfileId == profile.id ? .bold : .regular)
                                    Spacer()
                                    if dataManager.activeProfileId == profile.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("No Profiles Loaded").foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Preferences")) {
                    NavigationLink(destination: SettingsView(), tag: "settings", selection: $selectedProfileId) {
                        Label("Settings & Upgrades", systemImage: "gearshape")
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            // Default view when nothing is selected
            Text("Select a profile to view details")
                .foregroundColor(.secondary)
                .font(.title)
        }
    }
}

struct ProfileDetailView: View {
    @ObservedObject var dataManager: DataManager
    var profile: Profile
    
    var isActive: Bool {
        dataManager.activeProfileId == profile.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(profile.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isActive {
                    Text("Active Profile")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                } else {
                    Button(action: {
                        withAnimation {
                            dataManager.activeProfileId = profile.id
                        }
                    }) {
                        Text("Set as Active")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Divider()
            
            Text("Categories")
                .font(.title2)
                .fontWeight(.semibold)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(profile.categories) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.name)
                                .font(.headline)
                            
                            let examples = category.items.prefix(3)
                            let exampleText = examples.joined(separator: " • ")
                            Text(exampleText + (category.items.count > 3 ? " • ..." : ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Settings & Future Upgrades")
                .font(.title)
            
            Text("Future enhancements like local LLM integration and advanced customization will live here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
    }
}
