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

    @FocusState private var focusedWallpaper: WallpaperItem?

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
            focusedWallpaper: $focusedWallpaper,
            isDark: isDark,
            onSelect: { url in
                guard WallpaperCoordinator.isAvailableWallpaper(url) else {
                    return
                }
                wallpaperCoordinator.selectWallpaper(url, isDark: isDark)
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
        addImages(isDark: focusedWallpaper?.isDark ?? appearanceMonitor.isDarkMode)
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
        let target = focusedWallpaper ?? currentWallpaperItem
        guard let target else {
            return
        }

        removeWallpaper(target.url, isDark: target.isDark)
    }

    private var currentWallpaperItem: WallpaperItem? {
        let isDark = appearanceMonitor.isDarkMode
        guard let url = wallpaperCoordinator.currentWallpaper(isDark: isDark) else {
            return nil
        }
        return WallpaperItem(url: url, isDark: isDark)
    }

    private func removeWallpaper(_ url: URL, isDark: Bool) {
        if isDark {
            wallpaperCoordinator.darkWallpapers.removeAll { $0 == url }
        } else {
            wallpaperCoordinator.lightWallpapers.removeAll { $0 == url }
        }

        if focusedWallpaper == WallpaperItem(url: url, isDark: isDark) {
            focusedWallpaper = nil
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

private struct WallpaperItem: Hashable {
    let url: URL
    let isDark: Bool
}

private struct WallpaperCollectionSection: View {
    let title: String
    let subtitle: String
    @Binding var wallpapers: [URL]
    let currentWallpaper: URL?
    @FocusState.Binding var focusedWallpaper: WallpaperItem?
    let isDark: Bool
    let onSelect: (URL) -> Void
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

            Group {
                if wallpapers.isEmpty {
                    EmptyWallpaperState(
                        appearance: isDark ? "Dark" : "Light",
                        action: onAddImages
                    )
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                        ForEach(wallpapers, id: \.self) { wallpaper in
                            let item = WallpaperItem(url: wallpaper, isDark: isDark)
                            WallpaperThumbnailCard(
                                url: wallpaper,
                                isCurrent: wallpaper == currentWallpaper,
                                item: item,
                                focusedWallpaper: $focusedWallpaper,
                                onSelect: { onSelect(wallpaper) },
                                onReveal: { NSWorkspace.shared.activateFileViewerSelecting([wallpaper]) },
                                onRemove: { onRemove(wallpaper) },
                                onQuickLook: { onQuickLook(wallpaper) }
                            )
                        }

                        AddImagesTile(action: onAddImages)
                    }
                }
            }
            .padding(5)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isDropTargeted
                            ? Color.accentColor.opacity(0.7)
                            : wallpapers.isEmpty ? Color.secondary.opacity(0.24) : Color.clear,
                        style: StrokeStyle(
                            lineWidth: isDropTargeted ? 2 : 1,
                            dash: wallpapers.isEmpty && !isDropTargeted ? [5, 4] : []
                        )
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
    let item: WallpaperItem
    @FocusState.Binding var focusedWallpaper: WallpaperItem?
    let onSelect: () -> Void
    let onReveal: () -> Void
    let onRemove: () -> Void
    let onQuickLook: () -> Void

    @State private var isHovered = false

    private let cornerRadius: CGFloat = 11

    private var isFocused: Bool {
        focusedWallpaper == item
    }

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
        .focused($focusedWallpaper, equals: item)
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
            "\(url.lastPathComponent)\(isAvailable ? "" : ", unavailable")\(isCurrent ? ", selected current wallpaper" : "")\(isFocused ? ", keyboard focused" : "")"
        )
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeOut(duration: 0.12), value: isFocused)
    }

    private var borderColor: Color {
        if isCurrent {
            return Color.accentColor.opacity(0.72)
        }
        if isFocused {
            return Color.accentColor.opacity(0.4)
        }
        if isHovered {
            return Color.secondary.opacity(0.45)
        }
        return .clear
    }

    private var borderWidth: CGFloat {
        isFocused || isCurrent ? 2 : 1
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

private struct EmptyWallpaperState: View {
    let appearance: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 23, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("No wallpapers yet")
                    .font(.headline)

                Text("Add wallpapers for your Mac’s \(appearance) Appearance, or drag image files here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button(action: action) {
                Label("Add Images", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct AddImagesTile: View {
    let action: () -> Void

    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    private let cornerRadius: CGFloat = 11

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .aspectRatio(1.6, contentMode: .fit)
                .overlay {
                    Label("Add images", systemImage: "plus")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
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
