//
//  MenuBarPopoverView.swift
//  DuoScape
//

import AppKit
import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject private var wallpaperCoordinator = WallpaperCoordinator.shared
    @ObservedObject private var appearanceMonitor = AppearanceMonitor.shared

    let onOpenWallpaperLibrary: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    private var isDarkMode: Bool {
        appearanceMonitor.isDarkMode
    }

    private var currentWallpaper: URL? {
        wallpaperCoordinator.currentWallpaper(isDark: isDarkMode)
    }

    private var wallpapers: [URL] {
        isDarkMode ? wallpaperCoordinator.darkWallpapers : wallpaperCoordinator.lightWallpapers
    }

    private var appearanceTitle: String {
        isDarkMode ? "Dark Appearance" : "Light Appearance"
    }

    private var collectionTitle: String {
        isDarkMode ? "Dark collection" : "Light collection"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .foregroundStyle(.secondary)

                Text(appearanceTitle)
                    .font(.headline)

                Spacer(minLength: 0)
            }
            .padding(.bottom, 12)

            wallpaperPreview

            VStack(alignment: .leading, spacing: 4) {
                Text(currentWallpaper.map(displayName(for:)) ?? "No wallpaper selected")
                    .font(.system(.headline))
                    .lineLimit(1)
                    .truncationMode(.middle)

                let count = wallpapers.count
                Text("\(collectionTitle) · \(count) \(count == 1 ? "image" : "images")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 11)

            HStack(spacing: 8) {
                Button(action: nextWallpaper) {
                    Label("Next Wallpaper", systemImage: "forward.end.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(wallpapers.isEmpty)

                Button(action: applyNow) {
                    Label("Apply Now", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(currentWallpaper == nil)
            }
            .controlSize(.large)
            .padding(.top, 16)

            Divider()
                .padding(.vertical, 10)

            VStack(alignment: .leading, spacing: 2) {
                Button(action: onOpenWallpaperLibrary) {
                    Label("Open Wallpaper Library…", systemImage: "square.grid.2x2")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onOpenSettings) {
                    Label("Settings…", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .padding(.vertical, 8)

            Button(action: onQuit) {
                Label("Quit DuoScape", systemImage: "power")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(width: 360)
    }

    private var wallpaperPreview: some View {
        GeometryReader { geometry in
            Group {
                if let currentWallpaper,
                   let image = NSImage(contentsOf: currentWallpaper) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay {
                            VStack(spacing: 7) {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundStyle(.tertiary)

                                if wallpapers.isEmpty {
                                    Text("No wallpapers in this collection")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1.6, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityLabel(currentWallpaper.map(displayName(for:)) ?? "No wallpaper selected")
    }

    private func displayName(for wallpaper: URL) -> String {
        wallpaper.deletingPathExtension().lastPathComponent
    }

    private func applyNow() {
        wallpaperCoordinator.applyWallpaper(isDark: isDarkMode)
    }

    private func nextWallpaper() {
        wallpaperCoordinator.advanceAndApplyWallpaper(isDark: isDarkMode)
    }
}
