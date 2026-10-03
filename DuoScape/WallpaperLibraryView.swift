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
        VStack(spacing: 18) {
            WallpaperSectionView(
                title: "Light mode wallpapers",
                wallpapers: $wallpaperCoordinator.lightWallpapers
            )

            Divider()

            WallpaperSectionView(
                title: "Dark mode wallpapers",
                wallpapers: $wallpaperCoordinator.darkWallpapers
            )
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 660)
    }
}

private struct WallpaperSectionView: View {
    let title: String
    @Binding var wallpapers: [URL]

    @State private var selectedWallpapers: Set<URL> = []

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Text("\(wallpapers.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(wallpapers, id: \.self) { wallpaper in
                        WallpaperCardView(
                            url: wallpaper,
                            isSelected: selectedWallpapers.contains(wallpaper)
                        )
                        .onTapGesture {
                            toggleSelection(for: wallpaper)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
            .overlay {
                if wallpapers.isEmpty {
                    ContentUnavailableView(
                        "No images selected",
                        systemImage: "photo.on.rectangle",
                        description: Text("Add jpg, png, or heic files.")
                    )
                }
            }

            HStack(spacing: 10) {
                Button("Add images...") {
                    addImages()
                }

                Button("Remove selected") {
                    removeSelected()
                }
                .disabled(selectedWallpapers.isEmpty)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: wallpapers) { _, newValue in
            selectedWallpapers = selectedWallpapers.intersection(Set(newValue))
        }
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

        guard !newWallpapers.isEmpty else {
            return
        }

        wallpapers.append(contentsOf: newWallpapers)
    }

    private func removeSelected() {
        wallpapers.removeAll { selectedWallpapers.contains($0) }
        selectedWallpapers.removeAll()
    }

    private func toggleSelection(for wallpaper: URL) {
        if selectedWallpapers.contains(wallpaper) {
            selectedWallpapers.remove(wallpaper)
        } else {
            selectedWallpapers.insert(wallpaper)
        }
    }
}

private struct WallpaperCardView: View {
    let url: URL
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            thumbnail
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .padding(6)
                    }
                }

            Text(url.deletingPathExtension().lastPathComponent)
                .font(.system(size: 11))
                .foregroundStyle(Color.gray)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .frame(width: 160, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.18), lineWidth: isSelected ? 2 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder private var thumbnail: some View {
        if let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 160, height: 90)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.secondary.opacity(0.12))
                .frame(width: 160, height: 90)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
        }
    }
}
