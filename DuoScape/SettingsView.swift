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
    @State private var launchAtLogin = false
    @State private var launchAtLoginStatusText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle("Rotate wallpapers", isOn: $wallpaperCoordinator.rotateWallpaper)

            HStack {
                Text("Change wallpaper")

                Spacer()

                Picker("Rotation interval", selection: $wallpaperCoordinator.rotationInterval) {
                    ForEach(WallpaperRotationInterval.allCases) { interval in
                        Text(interval.title).tag(interval)
                    }
                }
                .labelsHidden()
                .frame(width: 190)
            }
            .padding(.leading, 22)
            .padding(.top, 8)
            .disabled(!wallpaperCoordinator.rotateWallpaper)

            Toggle(
                "Change wallpaper when system appearance changes",
                isOn: $wallpaperCoordinator.changeWallpaperWhenAppearanceChanges
            )
            .padding(.top, 18)

            Divider()
                .padding(.vertical, 14)

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        setLaunchAtLogin(newValue)
                    }
                ))

                if !launchAtLoginStatusText.isEmpty {
                    Text(launchAtLoginStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 22)
                }
            }

            Spacer(minLength: 12)

            if let versionDescription {
                Text(versionDescription)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(minWidth: 460, minHeight: 250, alignment: .topLeading)
        .onAppear(perform: refreshLaunchAtLoginStatus)
    }

    private var versionDescription: String? {
        guard let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            return nil
        }

        return "Version \(shortVersion) (\(buildVersion))"
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
            refreshLaunchAtLoginStatus()
            launchAtLoginStatusText = error.localizedDescription
            return
        }

        refreshLaunchAtLoginStatus()
    }

    private func refreshLaunchAtLoginStatus() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLogin = true
            launchAtLoginStatusText = ""
        case .requiresApproval:
            launchAtLogin = true
            launchAtLoginStatusText = "Requires approval in System Settings"
        case .notRegistered:
            launchAtLogin = false
            launchAtLoginStatusText = ""
        case .notFound:
            launchAtLogin = false
            launchAtLoginStatusText = "Login item unavailable"
        @unknown default:
            launchAtLogin = false
            launchAtLoginStatusText = "Status unavailable"
        }
    }
}
