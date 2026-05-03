# Ghostwriter Manual Testing Checklist

Since Ghostwriter uses the Swift Package Manager (SPM) for unit-testing its core logic (e.g., `Models` and `DataManager`), UI-level workflows are tested manually before a release.

Use this checklist to ensure the application behaves correctly.

## 1. Window Lifecycle & Dock Interaction
- [ ] Launch the app. The main window should appear.
- [ ] Close the main window (using the red traffic light button).
- [ ] Click the Ghostwriter icon in the macOS Dock. The main window should reappear and come to the front.
- [ ] Ensure that quitting the app via the menu bar (`Cmd + Q` or File > Quit) completely terminates the process.

## 2. Command Palette Workflow
- [ ] Open the command palette using the global shortcut (if configured) or from the UI.
- [ ] Type a filter query (e.g., "email"). The list should filter correctly to show only matching categories.
- [ ] Navigate the list using the `Up` and `Down` arrow keys.
- [ ] Press `Return` (Enter) on a selected category. It should copy a random item to the clipboard.
- [ ] Press `Escape` to close the command palette without taking an action.

## 3. Profile & Data Management
- [ ] Switch between different profiles in the main window sidebar. The categories should update accordingly.
- [ ] Create a new Profile.
- [ ] Add a new Category to a Profile and add items to it.
- [ ] Verify that navigating to the Command Palette shows the newly added Category.
- [ ] Modify an existing Category name. Verify the change is saved and reflected.
- [ ] Delete a Category. Verify it is removed.
- [ ] Quit the app and relaunch. Verify all data changes persisted correctly.

## 4. Clipboard Operations
- [ ] Select a row in the Command Palette or the Main Window.
- [ ] Verify that a value from the category is copied to the macOS clipboard.
- [ ] Paste the clipboard into a text editor to verify the correct text is present.

## 5. File Import/Export (If Applicable)
- [ ] Import a valid `data.json` file. The app should load the new data successfully.
- [ ] Try importing an invalid JSON file. An appropriate error alert should be shown without crashing the app.

---
**Run Unit Tests:**
Don't forget to run `swift test` in the terminal to verify the data models and logic!
