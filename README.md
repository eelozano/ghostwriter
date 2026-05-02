# Requirements: QA Synthetic Data "Ghostwriter"

## Overview
A lightweight macOS menu bar application designed for QA professionals to quickly inject random, domain-specific synthetic data into web forms and applications. The app prioritizes keyboard-driven workflows to eliminate the "context-switching tax" of manual data entry.

## Core Functionality

### 1. Profile-Based Data Management
* **Profiles:** The app supports multiple testing domains (e.g., "Faculty Information System," "ServiceNow").
* **Active Profile:** Only data types associated with the currently selected profile are available in the command palette.
* **Profile Switching:** Manual selection via the macOS menu bar icon.

### 2. Data Types & Randomization
* **Standard Types:** Support for Name, Email, Phone, and Paragraphs.
* **Custom Types:** Ability to define domain-specific types (e.g., "Faculty Interest Area," "Bio," "Internal ID").
* **Randomization:** Selecting a data type copies a **random** entry from the imported list to the system clipboard.

### 3. The Command Palette (Primary UI)
* **Trigger:** Global keyboard shortcut (e.g., `Cmd + Shift + P`).
* **Fuzzy Search:** A centered, minimal search bar that filters data types within the active profile.
* **Execution:**
    * User types "em" -> "Email" is highlighted.
    * User hits `Enter`.
    * A random email from the list is copied to the clipboard.
    * The palette automatically hides.

### 4. Data Import/Export
* **CSV/JSON Support:** Users can import data sets per profile.
* **Sample Export:** The app must provide a "Download Template" option for each profile to ensure users format their custom data correctly.
* **Persistence:** Data is stored locally for immediate access.

## Technical Requirements
* **Platform:** macOS (Menu Bar Application).
* **Clipboard Integration:** Data must be loaded directly into the system clipboard to bypass pasting issues in complex UI fields.
* **Performance:** The fuzzy search must be instantaneous, even with lists of several hundred entries.

## User Interface (UI) Goals
* **Minimalism:** No heavy windows. The app lives in the menu bar and the command palette.
* **Feedback:** Optional "Ghost" notification (small overlay) or system sound to confirm a successful copy.

## Future Roadmap
* **Profile Palette:** Ability to switch active profiles via the command palette.
* **Local LLM Integration:** Option to generate "Organic" data on the fly when pre-made lists are exhausted.