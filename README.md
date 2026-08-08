<p align="center">
  <img src="https://raw.githubusercontent.com/serhii-londar/iSimulator/master/iSimulator/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="iSimulator Logo">
</p>

<h1 align="center">iSimulator</h1>

<p align="center">
  <b>A fast, modern macOS menu bar utility for iOS, watchOS, and tvOS Simulator management.</b>
</p>

<p align="center">
  <a href="https://github.com/serhii-londar/iSimulator/releases"><img src="https://img.shields.io/github/v/release/serhii-londar/iSimulator?style=flat-square&color=blue" alt="Latest Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/serhii-londar/iSimulator?style=flat-square&color=green" alt="License"></a>
  <img src="https://img.shields.io/badge/macOS-10.15%2B-brightgreen?style=flat-square&logo=apple" alt="macOS 10.15+">
  <img src="https://img.shields.io/badge/Xcode-12.0%2B-orange?style=flat-square&logo=xcode" alt="Xcode 12.0+">
</p>

---

## Overview

**iSimulator** resides silently in your macOS menu bar to streamline your Apple platform development workflow. Instantly manage simulators, launch & debug applications, inspect sandboxes, reset state snapshots, test push notifications, override system appearance, and inspect `Info.plist` files — all without opening Terminal or deep-nested Xcode menus.

---

## Key Features

### 🚀 Command Palette & Fast Navigation
- **Quick Search Command Palette**: Instant Spotlight-like quick launcher to search, boot, shutdown, and open any simulator or application.
- **Favorites & Pinning**: Pin your most frequently used simulators and applications to the top of the menu bar for 1-click access.
- **Auto Refresh**: Automatically updates simulator and installed app states whenever devices or apps change.

### 📱 Simulator Controls
- **Multi-Device Operations**: Show, boot, shutdown, erase, or delete iOS, watchOS, and tvOS simulators.
- **Simulator Pairing**: Pair and unpair iPhone and Apple Watch simulators.
- **Appearance Control**: Toggle Light Mode / Dark Mode across active simulators.
- **Status Bar Clean Overrides**: Override simulator status bar (time, signal, battery) for clean App Store marketing screenshots.
- **Custom Deep Links / URLs**: Instantly open custom URL schemes directly on target simulators.

### 📦 Application & Sandbox Management
- **One-Click Folder Access**: Instantly open App Bundle, Application Sandbox, App Groups, Documents, Library, and Caches folders in Finder.
- **Cross-Simulator App Transfer**: Launch an application binary on another simulator without rebuilding in Xcode.
- **Sandbox Snapshots (State Machine)**: Save, restore, and delete sandbox data snapshots (ideal for testing DB states, auth flows, and data migrations).
- **APNs Push Notification Tester**: Simulate push notifications by sending custom JSON payload files directly to installed apps.
- **Info.plist Inspector**: Native GUI viewer and key-value search for any installed app's `Info.plist`.
- **Privacy & Permissions**: Reset or grant Location, Camera, Contacts, Photos, and Notification permissions.
- **Storage Usage**: Live disk usage calculation for application bundles and sandboxes.

---

## Requirements

- **macOS**: 10.15 (Catalina) or later
- **Xcode**: 12.0 or later (with Xcode Command Line Tools enabled)

> **Note**: iSimulator relies on `xcrun simctl`. Ensure your active developer directory is set properly in Xcode (**Preferences -> Locations -> Command Line Tools**) or via terminal:
> ```bash
> sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
> ```

---

## Installation

### Option 1: Download Pre-built App
Download the latest pre-compiled binary from [GitHub Releases](https://github.com/serhii-londar/iSimulator/releases).

### Option 2: Build from Source
Clone the repository and build using Xcode:

```bash
git clone https://github.com/serhii-londar/iSimulator.git
cd iSimulator
open iSimulator.xcodeproj
```

---

## Preview

<p align="center">
  <b>Simulator & Application Quick Menu</b><br>
  <img src="https://raw.githubusercontent.com/serhii-londar/iSimulator/master/preview/app.jpg" alt="Simulator Menu" width="360"/>
</p>

<p align="center">
  <b>Launch Applications Across Simulators</b><br>
  <img src="https://raw.githubusercontent.com/serhii-londar/iSimulator/master/preview/share.jpg" alt="Cross Simulator Share" width="360"/>
</p>

---

## Building & Publishing Releases

To build `iSimulator` in Release mode and publish a new GitHub Release:

```bash
# Auto-detect version from Xcode project (MARKETING_VERSION) and publish
./scripts/publish_release.sh

# Specify explicit release version tag
./scripts/publish_release.sh 4.0.0

# Test build and packaging locally without publishing to GitHub
./scripts/publish_release.sh --dry-run
```

---

## License

iSimulator is released under the **MIT License**. See [LICENSE](LICENSE) for details.