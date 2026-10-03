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
    private let popover = NSPopover()
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

        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(togglePopover)

        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(
                onOpenWallpaperLibrary: { [weak self] in self?.openWallpaperLibrary() },
                onOpenSettings: { [weak self] in self?.openSettings() },
                onQuit: { [weak self] in self?.quit() }
            )
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
    }

    private func openSettings() {
        popover.performClose(nil)
        let window = settingsWindow ?? makeWindow(
            rootView: SettingsView(),
            title: "Settings",
            size: NSSize(width: 520, height: 300),
            minimumSize: NSSize(width: 460, height: 250)
        )

        settingsWindow = window
        show(window)
    }

    private func openWallpaperLibrary() {
        popover.performClose(nil)
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

    private func quit() {
        popover.performClose(nil)
        NSApplication.shared.terminate(nil)
    }
}
