# DuoScape

DuoScape is a macOS menu bar utility for keeping separate wallpaper collections for Light and Dark Appearance. It has no Dock icon and applies the selected wallpaper for the active appearance.

## App surfaces

- **Menu bar popover** shows the active appearance, wallpaper preview, and collection, with **Apply Now**, **Next Wallpaper**, and links to the other surfaces.
- **Wallpaper Library** manages the Light and Dark collections in a separate image-first window.
- **Settings** contains scheduled rotation, appearance-change behavior, and launch-at-login options.

## Showcase

![DuoScape showing Light and Dark versions of a wallpaper](showcase.gif)

## Wallpaper behavior

- **Apply Now** applies the current selection for the active appearance without advancing.
- **Next Wallpaper** advances the active collection and applies the new selection.
- When timed rotation is enabled, each scheduled rotation advances the active collection and applies the new selection.
- When enabled, an appearance change applies the selected wallpaper from the matching collection.
- Launch and display-configuration refreshes reapply the current selection without advancing.

Wallpaper selections and rotation settings are stored in `UserDefaults`; launch at login uses `ServiceManagement`. Rotation intervals are 30 minutes, 1 hour, 3 hours, or **On login only**. The last option disables timed rotation; launching the app still applies the current selection.

## Build

Open `DuoScape.xcodeproj` in Xcode and run the `DuoScape` scheme, or build from the repository directory:

```sh
xcodebuild -project DuoScape.xcodeproj -scheme DuoScape -configuration Debug -derivedDataPath ./.derivedData build
```

## Implementation notes

- The project combines SwiftUI with AppKit for the status item, windows, and wallpaper application. `LSUIElement` keeps the app out of the Dock, and `ServiceManagement` handles launch at login.
- DuoScape applies wallpapers to each detected display with `NSWorkspace`.
- It also attempts to apply the wallpaper across all Spaces by updating Dock's `desktoppicture.db` and restarting Dock. This relies on macOS internals and may change or stop working in a future macOS release.
