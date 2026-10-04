# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project Overview

DuoScape is a small macOS SwiftUI and AppKit menu bar utility with no Dock icon. It has three surfaces: a menu bar popover, a Wallpaper Library window, and a Settings window. It keeps separate wallpaper collections and selections for Light and Dark Appearance.

**Apply Now** applies the current selection without advancing. **Next Wallpaper** and scheduled rotation advance the active collection and apply the new selection. When enabled, appearance changes apply the selection for the matching appearance. On launch, enabled rotation with **On login only** advances and applies the next wallpaper for the current appearance; otherwise launch and display-configuration refreshes reapply the current selection without advancing.

## Code Layout

- `DuoScape/DuoScapeApp.swift`
  - SwiftUI `@main` entry point and `AppDelegate`.
  - Creates `MenuBarController`, observes appearance changes, and applies the current selection on launch.
- `DuoScape/MenuBarController.swift`
  - Owns the `NSStatusItem`, popover, and reopenable Wallpaper Library and Settings windows.
- `DuoScape/MenuBarPopoverView.swift`
  - Shows the active appearance and wallpaper, and provides immediate wallpaper actions and navigation to the other surfaces.
- `DuoScape/WallpaperLibraryView.swift`
  - Manages the Light and Dark wallpaper collections and their selections.
- `DuoScape/SettingsView.swift`
  - Edits rotation, appearance-change, and launch-at-login settings.
- `DuoScape/AppearanceMonitor.swift`
  - Observes macOS appearance changes and publishes the current Light or Dark state.
- `DuoScape/WallpaperCoordinator.swift`
  - Owns wallpaper collections and selections, rotation settings and timer, persistence, and wallpaper application.
  - Applies wallpapers to detected screens and attempts all-Spaces support through the Dock desktop picture database.

## Build Command

Use this command for verification:

```sh
xcodebuild -project DuoScape.xcodeproj -scheme DuoScape -configuration Debug -derivedDataPath ./.derivedData build
```

After running the build, remove `.derivedData` unless the user asks to keep it:

```sh
rm -rf .derivedData
```

The build may emit CoreSimulator warnings in sandboxed environments. Treat them as non-blocking if the macOS target still reports `BUILD SUCCEEDED`.

## Project Conventions

- Prefer AppKit APIs where the app interacts with the menu bar, windows, wallpapers, or macOS system services.
- Keep state ownership in existing singletons:
  - Appearance state belongs in `AppearanceMonitor`.
  - Wallpaper collections, selections, indices, rotation interval, and timer behavior belong in `WallpaperCoordinator`.
  - Status-item and window actions belong in `MenuBarController`; popover wallpaper actions call `WallpaperCoordinator`.
- Keep `WallpaperLibraryView` focused on collection management and `SettingsView` focused on infrequent configuration. Write shared state through `WallpaperCoordinator.shared`.
- Use `UserDefaults` for simple persisted app settings unless there is a clear reason to introduce another store.
- Do not edit `project.pbxproj` unless Xcode target membership or build settings require it. The project currently picks up Swift files placed under `DuoScape/`.
- Avoid broad refactors. This is a small personal utility, so prefer straightforward code over abstractions that are not needed yet.

## macOS-Specific Notes

- `LSUIElement` is expected to be set in Info.plist/build settings so the app has no Dock icon.
- The menu bar icon uses the SF Symbol `photo.on.rectangle`.
- `ServiceManagement` login item changes should use `SMAppService.mainApp.register()` and `SMAppService.mainApp.unregister()`.
- All-Spaces wallpaper support touches `~/Library/Application Support/Dock/desktoppicture.db` and runs `killall Dock`. This depends on macOS internals and may break on future macOS versions.
- `NSWorkspace.shared.setDesktopImageURL(_:for:options:)` applies wallpaper to detected screens; keep the Dock database code separate and error-tolerant.

## Safety

- Do not run destructive commands like `git reset --hard` or `git checkout --` unless explicitly asked.
- Do not overwrite user changes. Check `git status --short` before and after edits.
- If changing wallpaper application behavior, keep failure paths non-fatal and log useful errors with `print`.
- Do not add network downloads or third-party dependencies without asking.
