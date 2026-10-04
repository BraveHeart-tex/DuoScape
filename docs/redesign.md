# DuoScape Redesign

DuoScape is a native macOS wallpaper utility that automatically switches between user-defined Light Mode and Dark Mode wallpaper collections as the system appearance changes.

The redesign direction is:

**Apple Wallpaper Settings meets Raycast**

The app should feel image-first, native, quiet, precise, and polished.

## Product concept

- Users choose one wallpaper collection for **Light Appearance** and another for **Dark Appearance**.
- DuoScape follows the current macOS appearance and applies the appropriate wallpaper automatically.
- Optional rotation can advance through the active collection on a chosen interval or on login.
- The app remains a menu bar utility.
- Configuration moves into a dedicated wallpaper library and a small settings surface.

## Product principle

> **The wallpaper is always the primary visual object.**

DuoScape should feel like a small, refined macOS utility that disappears when it is not needed and feels immediately understandable when opened.

## Application structure

The redesign separates DuoScape into three clear surfaces:

1. Menu bar popover
2. Wallpaper Library
3. Settings

## Menu bar popover

The menu bar experience should focus only on actions someone might need immediately.

Show:

- Current system state: **Light Appearance** or **Dark Appearance**
- Current wallpaper preview as the main visual element
- Current wallpaper name
- Collection context, for example:
  - `Downtown Sunset`
  - `Light collection · 4 images`

Primary actions:

- **Next Wallpaper**
- **Apply Now**

Secondary actions:

- **Open Wallpaper Library…**
- **Settings…**

Do not place configuration such as launch-at-login, rotation intervals, or file management in the popover.

## Wallpaper Library

The main window should feel like a native macOS media library rather than a traditional preferences form.

Use a stacked layout.

### Light mode wallpapers

Subtitle:

`Used while your Mac is in Light Appearance`

### Dark mode wallpapers

Subtitle:

`Used while your Mac is in Dark Appearance`

### Library behavior

- Use large, roughly 16:10 wallpaper thumbnails.
- Wallpapers should be the dominant visual objects.
- Include a simple **+ Add images** tile in each collection.
- Show the current or selected wallpaper visually on the thumbnail.
- De-emphasize filenames.
- Filenames can appear as subtle captions, tooltips, context-menu information, or inspector information when useful.

## Settings

Settings should contain configuration that users change infrequently.

Include:

- **Rotate wallpapers** toggle
- **Change wallpaper** interval selector
  - Every 30 minutes
  - 1 hour
  - 3 hours
  - On login only
- **Change wallpaper when system appearance changes** toggle
- **Launch at login** toggle
- App version and update information at the bottom if needed

Keep wallpaper management out of Settings.

## Visual language

- Use a native macOS aesthetic.
- Avoid making the app feel like an iOS interface running on macOS.
- Wallpaper imagery should provide most of the visual personality.
- Application chrome should remain quiet.
- Use neutral system colors.
- Use the macOS accent color mainly for selection and active states.
- Use system materials and subtle translucency where appropriate.
- Use crisp typography.
- Use restrained shadows.
- Use thin separators.
- Use approximately 10-12 px corner radii for wallpaper thumbnails.
- Use SF Symbols for interface iconography.

Useful icon concepts include:

- sun
- moon
- plus
- shuffle / rotate
- checkmark
- settings

Avoid:

- oversized SaaS-style cards
- decorative gradients in application chrome
- excessive rounding
- unnecessary metadata
- excessive explanatory text
- unnecessary borders

## Native macOS interactions

The app should take advantage of familiar macOS interactions.

Support:

- Drag and drop images directly into the Light or Dark collection.
- Context menus for wallpaper actions.
- **Reveal in Finder**
- **Remove**
- Space bar for Quick Look where practical.
- Delete key to remove a selected wallpaper.
- `⌘O` to add images or open the image-selection workflow.
- `⌘,` to open Settings.
- Clear hover states.
- Clear focus states.
- Clear selected states.
- Clear disabled states.
- Clear active/current wallpaper states.

## Interaction semantics

The redesign should clearly distinguish between the wallpaper that is currently selected and actions that move through the collection.

### Apply Now

Apply the currently selected wallpaper.

This action should not automatically advance to the next wallpaper.

### Next Wallpaper

Advance to the next wallpaper in the active Light or Dark collection and apply it.

### System appearance changes

When macOS changes between Light and Dark Appearance, apply the current wallpaper from the corresponding collection.

### Scheduled rotation

When rotation occurs, advance to the next wallpaper in the active collection and apply it.

When rotation is enabled with **On login only**, app launch advances to the next wallpaper for the current appearance and applies it. With rotation disabled or a timed interval selected, launch applies the current selection without advancing.

## Design inspiration

The strongest reference mix is:

### macOS Wallpaper Settings

Use as inspiration for:

- visual-first wallpaper galleries
- large image previews
- low-chrome media presentation
- native macOS spacing and hierarchy

### Raycast Themes / Settings

Use as inspiration for:

- clear Light vs Dark configuration
- compact utility UI
- polished native-feeling interactions
- restrained application chrome

### Equinox

Use as a product reference for wallpapers that respond to macOS appearance.

### Wallset and similar wallpaper menu bar utilities

Use as inspiration for keeping menu bar interaction immediate and image-focused.

## Naming and identity

The product name is **DuoScape**.

The name represents two coordinated visual environments:

- Light Appearance
- Dark Appearance

The app icon direction is a paired landscape:

- one side in daylight
- one side at night

The icon should communicate the Light/Dark relationship while still looking like a polished native macOS application.

## Redesign constraints

Preserve the existing core behavior unless the redesign explicitly requires a change:

- menu bar utility
- no Dock icon
- automatic Light/Dark appearance detection
- separate Light and Dark wallpaper collections
- wallpaper rotation
- launch at login
- wallpaper persistence
- wallpaper application across displays
- existing all-Spaces handling

Prefer small, focused changes over broad architectural rewrites.
