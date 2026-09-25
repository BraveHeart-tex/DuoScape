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
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var appearanceMonitor: AppearanceMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        appearanceMonitor = AppearanceMonitor.shared
        appearanceMonitor?.setOnChange { isDarkMode in
            let appearance = isDarkMode ? "dark" : "light"
            print("Appearance changed to: \(appearance)")
            WallpaperCoordinator.shared.applyWallpaper(isDark: isDarkMode)
        }

        WallpaperCoordinator.shared.applyWallpaper(isDark: AppearanceMonitor.shared.isDarkMode)
    }
}
