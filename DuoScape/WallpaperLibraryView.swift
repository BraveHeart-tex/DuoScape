//
//  WallpaperLibraryView.swift
//  DuoScape
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WallpaperLibraryView: View {
    @ObservedObject private var wallpaperCoordinator = WallpaperCoordinator.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                WallpaperCollectionSection(
                    title: "Light mode wallpapers",
                    subtitle: "Used while your Mac is in Light Appearance",
                    wallpapers: $wallpaperCoordinator.lightWallpapers,
                    currentWallpaper: wallpaperCoordinator.currentLightWallpaper,
                    onSelect: { wallpaperCoordinator.selectWallpaper($0, isDark: false) }
                )

                Divider()

                WallpaperCollectionSection(
                    title: "Dark mode wallpapers",
                    subtitle: "Used while your Mac is in Dark Appearance",
                    wallpapers: $wallpaperCoordinator.darkWallpapers,
                    currentWallpaper: wallpaperCoordinator.currentDarkWallpaper,
                    onSelect: { wallpaperCoordinator.selectWallpaper($0, isDark: true) }
                )
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 640, minHeight: 660)
    }
}

private struct WallpaperCollectionSection: View {
    let title: String
    let subtitle: String
    @Binding var wallpapers: [URL]
    let currentWallpaper: URL?
    let onSelect: (URL) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button {
                    removeSelectedWallpaper()
                } label: {
                    Label("Remove selected", systemImage: "minus.circle")
                }
                .buttonStyle(.borderless)
                .disabled(currentWallpaper == nil)
                .help("Remove the selected wallpaper from this collection")
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                ForEach(wallpapers, id: \.self) { wallpaper in
                    WallpaperThumbnailCard(
                        url: wallpaper,
                        isCurrent: wallpaper == currentWallpaper,
                        action: { onSelect(wallpaper) }
                    )
                }

                AddImagesTile(isEmpty: wallpapers.isEmpty, action: addImages)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func addImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .heic]

        guard panel.runModal() == .OK else {
            return
        }

        let existingWallpapers = Set(wallpapers)
        let newWallpapers = panel.urls.filter { !existingWallpapers.contains($0) }
        wallpapers.append(contentsOf: newWallpapers)
    }

    private func removeSelectedWallpaper() {
        guard let currentWallpaper else {
            return
        }

        wallpapers.removeAll { $0 == currentWallpaper }
    }
}

private struct WallpaperThumbnailCard: View {
    let url: URL
    let isCurrent: Bool
    let action: () -> Void

    private let cornerRadius: CGFloat = 11

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                thumbnail
                    .overlay(alignment: .topTrailing) {
                        if isCurrent {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.accentColor, in: Circle())
                                .padding(8)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                isCurrent ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    }

                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(url.lastPathComponent)
        .accessibilityLabel("\(url.lastPathComponent)\(isCurrent ? ", selected wallpaper" : "")")
    }

    private var thumbnail: some View {
        GeometryReader { geometry in
            Group {
                if let image = NSImage(contentsOf: url) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .aspectRatio(1.6, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct AddImagesTile: View {
    let isEmpty: Bool
    let action: () -> Void

    private let cornerRadius: CGFloat = 11

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isEmpty {
                    Text("No wallpapers yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Label("Add images", systemImage: "plus")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.6, contentMode: .fit)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.22), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add images")
    }
}
