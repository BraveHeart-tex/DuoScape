//
//  MenuBarController.swift
//  DuoScape
//
//  Created by Bora on 11.04.2026.
//

import AppKit
import SwiftUI

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private var settingsWindow: NSWindow?
    private var wallpaperLibraryWindow: NSWindow?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "photo.on.rectangle",
                accessibilityDescription: "DuoScape"
            )
            image?.isTemplate = true

            button.image = image
        }

        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(
            title: "Set wallpaper now",
            action: #selector(setWallpaperNow),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Wallpaper Library...",
            action: #selector(openWallpaperLibrary),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        menu.items.forEach { $0.target = self }

        return menu
    }

    @objc private func setWallpaperNow() {
        WallpaperCoordinator.shared.applyWallpaper(isDark: AppearanceMonitor.shared.isDarkMode)
    }

    @objc private func openSettings() {
        let window = settingsWindow ?? makeWindow(
            rootView: SettingsView(),
            title: "Settings",
            size: NSSize(width: 520, height: 300),
            minimumSize: NSSize(width: 460, height: 250)
        )

        settingsWindow = window
        show(window)
    }

    @objc private func openWallpaperLibrary() {
        let window = wallpaperLibraryWindow ?? makeWindow(
            rootView: WallpaperLibraryView(),
            title: "Wallpaper Library",
            size: NSSize(width: 760, height: 720),
            minimumSize: NSSize(width: 640, height: 660)
        )

        wallpaperLibraryWindow = window
        show(window)
    }

    private func makeWindow<Content: View>(
        rootView: Content,
        title: String,
        size: NSSize,
        minimumSize: NSSize
    ) -> NSWindow {
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = title
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(size)
        window.minSize = minimumSize
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    private func show(_ window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
