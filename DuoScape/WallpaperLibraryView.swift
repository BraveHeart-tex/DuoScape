//
//  WallpaperLibraryView.swift
//  DuoScape
//

import AppKit
import QuickLookUI
import SwiftUI
import UniformTypeIdentifiers

struct WallpaperLibraryView: View {
    @ObservedObject private var wallpaperCoordinator = WallpaperCoordinator.shared
    @ObservedObject private var appearanceMonitor = AppearanceMonitor.shared

    @State private var selectedWallpaper: WallpaperSelection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                collectionSection(
                    title: "Light mode wallpapers",
                    subtitle: "Used while your Mac is in Light Appearance",
                    wallpapers: $wallpaperCoordinator.lightWallpapers,
                    currentWallpaper: wallpaperCoordinator.currentLightWallpaper,
                    isDark: false
                )

                Divider()

                collectionSection(
                    title: "Dark mode wallpapers",
                    subtitle: "Used while your Mac is in Dark Appearance",
                    wallpapers: $wallpaperCoordinator.darkWallpapers,
                    currentWallpaper: wallpaperCoordinator.currentDarkWallpaper,
                    isDark: true
                )
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 640, minHeight: 660)
        .background {
            Button("Add Images", action: addImagesForKeyboardTarget)
                .keyboardShortcut("o", modifiers: .command)
                .hidden()
        }
        .onDeleteCommand(perform: removeSelectedWallpaper)
    }

    private func collectionSection(
        title: String,
        subtitle: String,
        wallpapers: Binding<[URL]>,
        currentWallpaper: URL?,
        isDark: Bool
    ) -> some View {
        WallpaperCollectionSection(
            title: title,
            subtitle: subtitle,
            wallpapers: wallpapers,
            currentWallpaper: currentWallpaper,
            isDark: isDark,
            selectedWallpaper: selectedWallpaper,
            onSelect: { url in
                guard WallpaperCoordinator.isAvailableWallpaper(url) else {
                    return
                }
                selectedWallpaper = WallpaperSelection(url: url, isDark: isDark)
                wallpaperCoordinator.selectWallpaper(url, isDark: isDark)
            },
            onFocus: { url in
                selectedWallpaper = WallpaperSelection(url: url, isDark: isDark)
            },
            onRemove: { url in
                removeWallpaper(url, isDark: isDark)
            },
            onQuickLook: { WallpaperQuickLookController.shared.show($0) },
            onAddImages: { addImages(isDark: isDark) },
            onDrop: { appendWallpapers($0, isDark: isDark) }
        )
    }

    private func addImagesForKeyboardTarget() {
        addImages(isDark: selectedWallpaper?.isDark ?? appearanceMonitor.isDarkMode)
    }

    private func addImages(isDark: Bool) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]

        guard panel.runModal() == .OK else {
            return
        }

        appendWallpapers(panel.urls, isDark: isDark)
    }

    private func appendWallpapers(_ urls: [URL], isDark: Bool) {
        var collection = isDark ? wallpaperCoordinator.darkWallpapers : wallpaperCoordinator.lightWallpapers
        var knownURLs = Set(collection.map(\.standardizedFileURL))

        for url in urls where Self.isSupportedImage(url) {
            let canonicalURL = url.standardizedFileURL
            guard knownURLs.insert(canonicalURL).inserted else {
                continue
            }
            collection.append(url)
        }

        if isDark {
            wallpaperCoordinator.darkWallpapers = collection
        } else {
            wallpaperCoordinator.lightWallpapers = collection
        }
    }

    private func removeSelectedWallpaper() {
        guard let selectedWallpaper else {
            return
        }

        removeWallpaper(selectedWallpaper.url, isDark: selectedWallpaper.isDark)
    }

    private func removeWallpaper(_ url: URL, isDark: Bool) {
        if isDark {
            wallpaperCoordinator.darkWallpapers.removeAll { $0 == url }
        } else {
            wallpaperCoordinator.lightWallpapers.removeAll { $0 == url }
        }

        if selectedWallpaper == WallpaperSelection(url: url, isDark: isDark) {
            selectedWallpaper = nil
        }
        if WallpaperQuickLookController.shared.previewedURL == url {
            WallpaperQuickLookController.shared.close()
        }
    }

    fileprivate static func isSupportedImage(_ url: URL) -> Bool {
        guard url.isFileURL,
              UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true,
              WallpaperCoordinator.isAvailableWallpaper(url) else {
            return false
        }

        return true
    }
}

private final class WallpaperQuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = WallpaperQuickLookController()

    private(set) var previewedURL: URL?

    func show(_ url: URL) {
        guard WallpaperCoordinator.isAvailableWallpaper(url) else {
            return
        }

        previewedURL = url
        guard let panel = QLPreviewPanel.shared() else {
            previewedURL = nil
            return
        }
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        QLPreviewPanel.shared()?.close()
        previewedURL = nil
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel) -> Int {
        previewedURL == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel, previewItemAt index: Int) -> QLPreviewItem {
        previewedURL! as NSURL
    }
}

private struct WallpaperSelection: Equatable {
    let url: URL
    let isDark: Bool
}

private struct WallpaperCollectionSection: View {
    let title: String
    let subtitle: String
    @Binding var wallpapers: [URL]
    let currentWallpaper: URL?
    let isDark: Bool
    let selectedWallpaper: WallpaperSelection?
    let onSelect: (URL) -> Void
    let onFocus: (URL) -> Void
    let onRemove: (URL) -> Void
    let onQuickLook: (URL) -> Void
    let onAddImages: () -> Void
    let onDrop: ([URL]) -> Void

    @State private var isDropTargeted = false

    private let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                ForEach(wallpapers, id: \.self) { wallpaper in
                    WallpaperThumbnailCard(
                        url: wallpaper,
                        isCurrent: wallpaper == currentWallpaper,
                        isSelected: selectedWallpaper == WallpaperSelection(url: wallpaper, isDark: isDark),
                        onSelect: { onSelect(wallpaper) },
                        onFocus: { onFocus(wallpaper) },
                        onReveal: { NSWorkspace.shared.activateFileViewerSelecting([wallpaper]) },
                        onRemove: { onRemove(wallpaper) },
                        onQuickLook: { onQuickLook(wallpaper) }
                    )
                }

                AddImagesTile(isEmpty: wallpapers.isEmpty, action: onAddImages)
            }
            .padding(5)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isDropTargeted ? Color.accentColor.opacity(0.65) : Color.clear,
                        lineWidth: 2
                    )
                    .padding(-5)
                    .allowsHitTesting(false)
            }
            .animation(.easeOut(duration: 0.12), value: isDropTargeted)
            .onDrop(
                of: [UTType.fileURL.identifier],
                isTargeted: $isDropTargeted,
                perform: handleDrop
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }

        guard !fileProviders.isEmpty else {
            return false
        }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let url = Self.fileURL(from: item) else {
                    return
                }

                DispatchQueue.main.async {
                    guard WallpaperLibraryView.isSupportedImage(url) else {
                        return
                    }
                    onDrop([url])
                }
            }
        }

        return true
    }

    private static func fileURL(from item: NSSecureCoding?) -> URL? {
        switch item {
        case let url as URL:
            return url
        case let url as NSURL:
            return url as URL
        case let data as Data:
            return URL(dataRepresentation: data, relativeTo: nil)
        case let string as String:
            if let url = URL(string: string), url.isFileURL {
                return url
            }
            return URL(fileURLWithPath: string)
        default:
            return nil
        }
    }
}

private struct WallpaperThumbnailCard: View {
    let url: URL
    let isCurrent: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onFocus: () -> Void
    let onReveal: () -> Void
    let onRemove: () -> Void
    let onQuickLook: () -> Void

    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    private let cornerRadius: CGFloat = 11

    private var isAvailable: Bool {
        WallpaperCoordinator.isAvailableWallpaper(url)
    }

    var body: some View {
        Button(action: onSelect) {
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
                    .overlay(alignment: .topLeading) {
                        if !isAvailable {
                            Text("Unavailable")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(8)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    }

                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isAvailable ? 1 : 0.55)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .onChange(of: isFocused) { _, focused in
            if focused && isAvailable {
                onFocus()
            }
        }
        .onHover { isHovered = $0 }
        .onKeyPress(.space) {
            if isAvailable {
                onQuickLook()
            }
            return .handled
        }
        .contextMenu {
            Button("Reveal in Finder", systemImage: "folder", action: onReveal)
                .disabled(!isAvailable)

            Button("Remove", systemImage: "trash", role: .destructive, action: onRemove)
        }
        .help(url.lastPathComponent)
        .accessibilityLabel(
            "\(url.lastPathComponent)\(isAvailable ? "" : ", unavailable")\(isSelected ? ", selected" : "")\(isCurrent ? ", current wallpaper" : "")"
        )
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeOut(duration: 0.12), value: isFocused)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }

    private var borderColor: Color {
        if isSelected || isFocused {
            return Color.accentColor
        }
        if isHovered {
            return Color.secondary.opacity(0.45)
        }
        if isCurrent {
            return Color.accentColor.opacity(0.72)
        }
        return .clear
    }

    private var borderWidth: CGFloat {
        isSelected || isFocused || isCurrent ? 2 : 1
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

    @State private var isHovered = false
    @FocusState private var isFocused: Bool

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
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .onHover { isHovered = $0 }
        .accessibilityLabel("Add images")
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeOut(duration: 0.12), value: isFocused)
    }

    private var borderColor: Color {
        if isFocused {
            return Color.accentColor
        }
        return isHovered ? Color.secondary.opacity(0.45) : Color.secondary.opacity(0.22)
    }
}
