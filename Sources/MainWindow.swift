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
    
    @State private var showAddProfile = false
    @State private var profileToRename: Profile?
    @State private var profileToDelete: Profile?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedProfileId) {
                Section(header: HStack {
                    Text("Profiles")
                    Spacer()
                    Button(action: { showAddProfile = true }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(PlainButtonStyle())
                }) {
                    if let data = dataManager.data {
                        ForEach(data.profiles) { profile in
                            NavigationLink(value: profile.id) {
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
                            .contextMenu {
                                Button("Rename") { profileToRename = profile }
                                Button("Delete") { profileToDelete = profile }
                            }
                        }
                    } else {
                        Text("No Profiles Loaded").foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Preferences")) {
                    NavigationLink(value: "settings") {
                        Label("Settings & Upgrades", systemImage: "gearshape")
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
        } detail: {
            if let selectedId = selectedProfileId {
                if selectedId == "settings" {
                    SettingsView(dataManager: dataManager)
                } else {
                    ProfileDetailView(dataManager: dataManager, profileId: selectedId)
                }
            } else {
                Text("Select a profile to view details")
                    .foregroundColor(.secondary)
                    .font(.title)
            }
        }
        .accentColor(Color(red: 0.18, green: 0.35, blue: 0.55)) // Deep Ghostwriter Blue
        .sheet(isPresented: $showAddProfile) {
            AddProfileView(dataManager: dataManager)
        }
        .sheet(item: $profileToRename) { profile in
            RenameProfileView(dataManager: dataManager, profile: profile)
        }
        .alert("Delete Profile", isPresented: Binding(
            get: { profileToDelete != nil },
            set: { if !$0 { profileToDelete = nil } }
        ), presenting: profileToDelete) { profile in
            Button("Delete", role: .destructive) {
                dataManager.deleteProfile(id: profile.id)
                if selectedProfileId == profile.id {
                    selectedProfileId = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { profile in
            Text("Are you sure you want to delete '\(profile.name)'?")
        }
    }
}

struct ProfileDetailView: View {
    @ObservedObject var dataManager: DataManager
    let profileId: String

    // Live lookup — always reflects latest state after any mutation
    var profile: Profile? {
        dataManager.data?.profiles.first(where: { $0.id == profileId })
    }

    var isActive: Bool {
        dataManager.activeProfileId == profileId
    }

    @State private var editingCategoryId: String? = nil
    @State private var showAddCategory = false

    var body: some View {
        Group {
            if let profile = profile {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile header
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
                                withAnimation { dataManager.activeProfileId = profileId }
                            }) {
                                Text("Set as Active")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Categories")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            showAddCategory = true
                        } label: {
                            Label("Add Category", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                    }

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(profile.categories) { category in
                                CategoryCard(category: category)
                                    .onTapGesture {
                                        editingCategoryId = category.id
                                    }
                            }

                            if profile.categories.isEmpty {
                                Text("No categories yet. Tap '+ Add Category' to create one.")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 40)
                            }
                        }
                    }
                }
                .padding()
                .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity, alignment: .topLeading)
                // Category editor sheet
                .sheet(item: Binding(
                    get: { editingCategoryId.map { IdentifiableString(value: $0) } },
                    set: { editingCategoryId = $0?.value }
                )) { wrapper in
                    CategoryEditorView(dataManager: dataManager, profileId: profileId, categoryId: wrapper.value)
                }
                // Add category sheet
                .sheet(isPresented: $showAddCategory) {
                    AddCategoryView(dataManager: dataManager, profileId: profileId)
                }
            } else {
                Text("Profile not found.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// Tappable category card — visually indicates it's interactive
struct CategoryCard: View {
    let category: Category
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(.headline)
                Spacer()
                Image(systemName: "pencil")
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0)
            }
            let examples = category.items.prefix(3)
            let exampleText = examples.joined(separator: " • ")
            Text(
                category.items.isEmpty
                ? "No items yet."
                : exampleText + (category.items.count > 3 ? " • ..." : "")
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(2)

            Text("\(category.items.count) item\(category.items.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? Color.accentColor.opacity(0.07) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .cursor(.pointingHand)
    }
}

// Helper to make an optional String sheet-presentable via Identifiable
struct IdentifiableString: Identifiable {
    let value: String
    var id: String { value }
}

// Extension to set cursor on hover
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}



struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Settings & Data Management")
                .font(.title)
            
            Text("Manage your synthetic data profiles and application settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                
            Divider()
                .padding(.vertical)
                
            Text("Data Management")
                .font(.title2)
                .fontWeight(.semibold)
                
            HStack(spacing: 20) {
                Button(action: importData) {
                    Label("Import Data...", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: downloadTemplate) {
                    Label("Download Template...", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
    }
    
    private func importData() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                dataManager.importData(from: url)
            }
        }
    }
    
    private func downloadTemplate() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "ghostwriter-template.json"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                dataManager.generateTemplate(at: url)
            }
        }
    }
}

// MARK: - Profile Management Sheets

struct AddProfileView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var profileName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Profile")
                .font(.title2).fontWeight(.bold)

            TextField("Profile name", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .onSubmit { commit() }

            HStack {
                Spacer()
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") { commit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 360)
        .accentColor(Color(red: 0.18, green: 0.35, blue: 0.55))
    }

    private func commit() {
        let trimmed = profileName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dataManager.addProfile(name: trimmed)
        presentationMode.wrappedValue.dismiss()
    }
}

struct RenameProfileView: View {
    @ObservedObject var dataManager: DataManager
    let profile: Profile
    @Environment(\.presentationMode) var presentationMode
    @State private var profileName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Rename Profile")
                .font(.title2).fontWeight(.bold)

            TextField("Profile name", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .onSubmit { commit() }
                .onAppear {
                    profileName = profile.name
                }

            HStack {
                Spacer()
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Rename") { commit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 360)
        .accentColor(Color(red: 0.18, green: 0.35, blue: 0.55))
    }

    private func commit() {
        let trimmed = profileName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dataManager.renameProfile(id: profile.id, newName: trimmed)
        presentationMode.wrappedValue.dismiss()
    }
}
