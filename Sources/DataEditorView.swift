import SwiftUI
import AppKit

// MARK: - Category Editor Sheet

struct CategoryEditorView: View {
    @ObservedObject var dataManager: DataManager
    let profileId: String
    let categoryId: String
    @Environment(\.presentationMode) var presentationMode

    // Local mutable state
    @State private var editedName: String = ""
    @State private var bulkText: String = ""
    @State private var singleItem: String = ""
    @State private var copyToProfileId: String = ""
    @State private var includeItems: Bool = true
    @State private var showDeleteConfirm = false

    // Live category lookup so we always show current data
    var category: Category? {
        dataManager.data?.profiles.first(where: { $0.id == profileId })?.categories.first(where: { $0.id == categoryId })
    }

    var otherProfiles: [Profile] {
        dataManager.data?.profiles.filter({ $0.id != profileId }) ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Edit Category")
                    .font(.title2).fontWeight(.bold)
                Spacer()
                Button("Done") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Rename ──────────────────────────────────────────────
                    Group {
                        Text("Category Name").font(.headline)
                        HStack {
                            TextField("Name", text: $editedName)
                                .textFieldStyle(.roundedBorder)
                            Button("Rename") {
                                let trimmed = editedName.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                dataManager.renameCategory(profileId: profileId, categoryId: categoryId, newName: trimmed)
                            }
                            .buttonStyle(.bordered)
                            .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    Divider()

                    // ── Current Items ────────────────────────────────────────
                    Group {
                        Text("Items (\(category?.items.count ?? 0))").font(.headline)

                        if let items = category?.items, !items.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                                    HStack {
                                        Text(item)
                                            .font(.system(.body, design: .monospaced))
                                        Spacer()
                                        Button {
                                            dataManager.deleteItem(at: idx, profileId: profileId, categoryId: categoryId)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                }
                            }
                        } else {
                            Text("No items yet.").foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // ── Add Single Item ──────────────────────────────────────
                    Group {
                        Text("Add Item").font(.headline)
                        HStack {
                            TextField("New item value", text: $singleItem)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { commitSingleItem() }
                            Button("Add") { commitSingleItem() }
                                .buttonStyle(.borderedProminent)
                                .disabled(singleItem.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    Divider()

                    // ── Bulk Add ─────────────────────────────────────────────
                    Group {
                        Text("Bulk Add Items").font(.headline)
                        Text("Paste items below, one per line.")
                            .font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $bulkText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 100, maxHeight: 160)
                            .border(Color.gray.opacity(0.3), width: 1)
                            .cornerRadius(6)
                        Button("Add All Lines") {
                            let lines = bulkText
                                .components(separatedBy: .newlines)
                                .map { $0.trimmingCharacters(in: .whitespaces) }
                                .filter { !$0.isEmpty }
                            if !lines.isEmpty {
                                dataManager.addItems(lines, profileId: profileId, categoryId: categoryId)
                                bulkText = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(bulkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    // ── Copy to Profile ──────────────────────────────────────
                    if !otherProfiles.isEmpty {
                        Divider()
                        Group {
                            Text("Copy to Another Profile").font(.headline)
                            Picker("Target Profile", selection: $copyToProfileId) {
                                ForEach(otherProfiles) { profile in
                                    Text(profile.name).tag(profile.id)
                                }
                            }
                            .pickerStyle(.menu)
                            Toggle("Include Items", isOn: $includeItems)
                            Button("Copy Category") {
                                let target = copyToProfileId.isEmpty ? (otherProfiles.first?.id ?? "") : copyToProfileId
                                dataManager.copyCategory(
                                    categoryId: categoryId,
                                    fromProfileId: profileId,
                                    toProfileId: target,
                                    includeItems: includeItems
                                )
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Divider()

                    // ── Danger Zone ──────────────────────────────────────────
                    Group {
                        Text("Danger Zone").font(.headline).foregroundColor(.red)
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Category", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding()
            }
        }
        .frame(width: 520, height: 680)
        .accentColor(Color(red: 0.18, green: 0.35, blue: 0.55))
        .onAppear {
            editedName = category?.name ?? ""
            copyToProfileId = otherProfiles.first?.id ?? ""
        }
        .alert("Delete \"\(category?.name ?? "")\"?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                dataManager.deleteCategory(profileId: profileId, categoryId: categoryId)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the category and all its items.")
        }
    }

    private func commitSingleItem() {
        let trimmed = singleItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dataManager.addItem(trimmed, profileId: profileId, categoryId: categoryId)
        singleItem = ""
    }
}

// MARK: - Add Category Sheet

struct AddCategoryView: View {
    @ObservedObject var dataManager: DataManager
    let profileId: String
    @Environment(\.presentationMode) var presentationMode

    @State private var categoryName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Category")
                .font(.title2).fontWeight(.bold)

            TextField("Category name (e.g. Phone Number)", text: $categoryName)
                .textFieldStyle(.roundedBorder)
                .onSubmit { commit() }

            HStack {
                Spacer()
                Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") { commit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
        .accentColor(Color(red: 0.18, green: 0.35, blue: 0.55))
    }

    private func commit() {
        let trimmed = categoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dataManager.addCategory(profileId: profileId, name: trimmed)
        presentationMode.wrappedValue.dismiss()
    }
}
