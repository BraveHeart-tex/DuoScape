//
//  DuoScapeApp.swift
//  DuoScape
//
//  Created by Bora on 11.04.2026.
//

import SwiftUI

@main
struct DuoScapeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    appDelegate.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var appearanceMonitor: AppearanceMonitor?

    func openSettings() {
        menuBarController?.openSettings()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        appearanceMonitor = AppearanceMonitor.shared
        appearanceMonitor?.setOnChange { isDarkMode in
            let appearance = isDarkMode ? "dark" : "light"
            print("Appearance changed to: \(appearance)")

            guard WallpaperCoordinator.shared.changeWallpaperWhenAppearanceChanges else {
                return
            }

            WallpaperCoordinator.shared.applyWallpaper(isDark: isDarkMode)
        }

        WallpaperCoordinator.shared.applyWallpaperForLaunch(
            isDark: AppearanceMonitor.shared.isDarkMode
        )
    }
}
