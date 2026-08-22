# Flicker

**[中文](README.md)** | English

<p align="center">
  <img src="screenshots/app-logo.png" alt="Flicker" width="256" />
</p>

<p align="center">
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13+" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5-orange" alt="Swift 5" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT" /></a>
</p>

A minimalist macOS Finder right-click menu extension — open files and folders with your pre-configured apps instantly, copy paths, and create common files without leaving Finder.

## Screenshots

<p align="center">
  <img src="screenshots/image1.png" alt="Configuration UI" width="480" />
  <br/>
  <em>App configuration — set file extensions for each app</em>
</p>

<p align="center">
  <img src="screenshots/image2.png" alt="Finder context menu" width="480" />
  <br/>
  <em>Finder context menu — one-click open & path copying</em>
</p>

## Features

- Right-click files/folders to open with pre-configured applications
- Place configured apps either inside the Open With submenu or directly in the Finder context menu
- Copy absolute paths, relative paths, or file names to clipboard
- Create common file types from the Finder context menu, with optional auto-open after creation
- Configure app list with per-app file extension filters inside the container app
- "Folders only" mode for fine-grained menu visibility control
- Toggle Flicker's Finder context menu output, hide the Dock icon, and reduce main-window visibility in window managers

## Project Structure

```
Flicker/
├── App/          # App entry, config list, add/edit panels, store
├── Shared/       # AppEntry (data model), SharedStore (App Group read/write)
└── Resources/    # Info.plist, entitlements, Assets

FlickerExtension/   # Finder Sync extension (FIFinderSync subclass)
```

## Getting Started

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.2+ (for building; the latest version installable on macOS 13 — use Xcode 16+ on macOS 14)

### Build & Run

```bash
# Command-line build
xcodebuild -project Flicker.xcodeproj -scheme Flicker -configuration Debug build

# Or open Flicker.xcodeproj in Xcode, select the Flicker scheme and hit Run
```

### Package as DMG

```bash
./scripts/build_dmg.sh
# Output: dist/Flicker-<version>.dmg
```

### Enable the Extension

1. Launch Flicker, click **Add** to select a `.app`, then set its name, file extensions, and menu collapse behavior
2. Click **Manage Finder Extension…** at the bottom, then check Flicker under **System Settings → Privacy & Security → Extensions → Finder**
3. Restart Finder (`killall Finder`) — right-click in Finder to see the menu

## Configuration After Forking

If you fork this project and plan to build your own copy, update these values to your own:

| Setting | Current Value | Location |
|---------|---------------|----------|
| Bundle Identifier (App) | `com.wangyanan.flicker` | `project.pbxproj` |
| Bundle Identifier (Extension) | `com.wangyanan.flicker.extension` | `project.pbxproj` |
| App Group | `group.com.wangyanan.flicker` | `Shared/SharedStore.swift` + both `.entitlements` |
| URL Scheme | `flicker` | `Resources/Info.plist` |

> **Tip:** On macOS 13/14 the App Group container needs no registration on the Developer portal — ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`) works for local development. On macOS 15+ app group containers are protected and require a Team-ID-prefixed group ID or a provisioning profile.

## Technical Notes

- Relative paths are based on the current Finder window folder (`targetedURL`); falls back to absolute path when unavailable
- Configuration is shared between the app and extension via JSON files in the App Group container (`~/Library/Group Containers/group.com.wangyanan.flicker/`)
- Finder Sync extensions are hosted by macOS; quitting Flicker does not unload the extension. To temporarily hide Flicker's menu output, disable **Enable Finder Context Menu** in Action Control
- Minimum deployment target: macOS 13.0 (Ventura)

## Contributing

Issues and Pull Requests are welcome!

- Make sure the code compiles and runs before submitting a PR
- Open an issue first to discuss new features
- Keep code style consistent with the existing codebase

## License

This project is licensed under the [MIT License](LICENSE).
