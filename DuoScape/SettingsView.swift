//
//  SettingsView.swift
//  DuoScape
//
//  Created by Bora on 11.04.2026.
//

import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var wallpaperCoordinator = WallpaperCoordinator.shared
    @State private var rotateWallpaper = false
    @State private var rotationInterval: WallpaperRotationInterval = .onLoginOnly
    @State private var launchAtLogin = false
    @State private var launchAtLoginStatusText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Rotate wallpapers", isOn: $rotateWallpaper)

                HStack {
                    Text("Change wallpaper")

                    Spacer()

                    Picker("Rotation interval", selection: $rotationInterval) {
                        ForEach(WallpaperRotationInterval.allCases) { interval in
                            Text(interval.title).tag(interval)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 190)
                }

                Toggle(
                    "Change wallpaper when system appearance changes",
                    isOn: $wallpaperCoordinator.changeWallpaperWhenAppearanceChanges
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        setLaunchAtLogin(newValue)
                    }
                ))

                Text(launchAtLoginStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 22)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 460, minHeight: 250, alignment: .topLeading)
        .onAppear {
            rotateWallpaper = wallpaperCoordinator.rotateWallpaper
            rotationInterval = wallpaperCoordinator.rotationInterval
            refreshLaunchAtLoginStatus()
        }
        .onChange(of: rotateWallpaper) { _, newValue in
            wallpaperCoordinator.rotateWallpaper = newValue
        }
        .onChange(of: rotationInterval) { _, newValue in
            wallpaperCoordinator.rotationInterval = newValue
        }
    }

    private func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error.localizedDescription)")
        }

        refreshLaunchAtLoginStatus()
    }

    private func refreshLaunchAtLoginStatus() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLogin = true
            launchAtLoginStatusText = "Enabled"
        case .requiresApproval:
            launchAtLogin = true
            launchAtLoginStatusText = "Requires approval in System Settings"
        case .notRegistered:
            launchAtLogin = false
            launchAtLoginStatusText = "Disabled"
        case .notFound:
            launchAtLogin = false
            launchAtLoginStatusText = "Login item unavailable"
        @unknown default:
            launchAtLogin = false
            launchAtLoginStatusText = "Status unavailable"
        }
    }
}
