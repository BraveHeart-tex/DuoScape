# DuoScape Redesign Assessment

## Current implementation

DuoScape keeps its menu bar architecture, `AppearanceMonitor`, `WallpaperCoordinator`, `UserDefaults`, and `SMAppService`. The app presents a menu bar popover for immediate actions, a Wallpaper Library for Light and Dark collections, and Settings for rotation, appearance-change, and launch-at-login preferences.

The library stores a selected wallpaper for each appearance. **Apply Now** applies the selection for the active appearance without advancing. **Next Wallpaper** and scheduled rotation advance that collection and apply the new selection. When enabled, appearance changes apply the selection for the matching appearance. Launch and screen-configuration refreshes reapply the current selection without advancing.

Wallpaper application targets each detected display and also attempts all-Spaces support through Dock's desktop picture database. That all-Spaces behavior depends on macOS internals and may change.

## Redesign implementation status

1. **Separate selection, application, and advancement** - Complete.
2. **Separate the Wallpaper Library from Settings** - Complete.
3. **Build the image-first library** - Complete.
4. **Add the focused menu bar popover** - Complete.
5. **Add the library's native interactions** - Complete.
6. **Finish Settings and keyboard access** - Complete.
7. **Update project-facing documentation** - Complete.
