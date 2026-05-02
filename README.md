# Ghostwriter: QA Synthetic Data Injector

## Overview
Ghostwriter is a macOS application designed for QA professionals to quickly inject random, domain-specific synthetic data into web forms and applications. 

The application prioritizes keyboard-driven workflows to eliminate the "context-switching tax" of manual data entry. Instead of switching back and forth between a spreadsheet and your browser, Ghostwriter runs in the background and its Command Palette is summoned instantly via a global keyboard shortcut.

## Core Features

* **Keyboard-Driven Workflow:** Trigger the Command Palette globally using `Cmd + Shift + P`. Use instantaneous fuzzy search to find the data type you need, hit `Enter`, and paste!
* **Main Window Interface:** Easily manage your preferences, import data, and select active profiles through a standard macOS window.
* **Profile-Based Data Management:** Create different testing profiles (e.g., "Faculty Information System," "E-Commerce QA"). Only data types associated with the active profile appear in the palette.
* **Randomization:** Selecting a data category (like "Email" or "First Name") copies a randomly selected entry from your provided dataset directly to the system clipboard (`NSPasteboard`).

## Key Files & Architecture

The application is built natively for macOS using Swift, SwiftUI, and AppKit. It leverages the Carbon framework for robust global hotkey registration to ensure the command palette works anywhere.

* `Sources/main.swift`: The explicit entry point that bootstraps the Cocoa event loop.
* `Sources/AppDelegate.swift`: Manages the application lifecycle, sets up the main application menu, and registers the global Carbon event hotkey.
* `Sources/MainWindow.swift`: The primary application window for configuration and profile management.
* `Sources/CommandPalette.swift`: Contains the SwiftUI floating panel UI, fuzzy search logic, and keyboard navigation handling.
* `Sources/DataManager.swift`: Handles loading, parsing, and saving the profile datasets (JSON) to your local `~/Library/Application Support/Ghostwriter/` folder.
* `Sources/Models.swift`: Defines the `Profile` and `Category` Swift data structures.
* `build.sh`: A shell script that compiles the raw Swift files into a valid macOS `.app` bundle using `swiftc`.
* `ghostwriter-sample.json`: A sample dataset to help you get started or to feed into an LLM for generating custom synthetic data.

## How to Build Locally

You do not need a full Xcode IDE setup to build this application. A simple shell script is provided to compile the raw Swift files directly from your terminal.

1. **Clone the repository:**
   ```bash
   git clone git@github.com:eelozano/ghostwriter.git
   cd ghostwriter
   ```

2. **Run the build script:**
   ```bash
   bash build.sh
   ```
   This script creates the `Ghostwriter.app` bundle in your current directory, compiles the Swift source files into the bundle's `MacOS` directory, and copies over the `Info.plist`.

3. **Launch the app:**
   ```bash
   open Ghostwriter.app
   ```
   *Note: macOS Gatekeeper may block the app since it is compiled locally without an Apple Developer signature. If you experience issues opening it, you can clear the macOS quarantine flag by running: `xattr -cr Ghostwriter.app` in your terminal.*

## Getting Started
1. Launch the Ghostwriter app. You will see its icon in your Dock and its Main Menu at the top of your screen.
2. From the Main Menu, click **File > Import Data...** to load the provided `ghostwriter-sample.json` file.
3. You can manage your active profile via the **Preferences** window (or `Cmd + ,`).
4. From anywhere on your Mac, press **`Cmd + Shift + P`** to bring up the floating Command Palette. Search for a data type, hit `Enter`, and paste your new random data!