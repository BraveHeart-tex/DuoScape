//
//  WallpaperCoordinator.swift
//  DuoScape
//
//  Created by Bora on 11.04.2026.
//

import AppKit
import Combine
import SQLite3

enum WallpaperRotationInterval: String, CaseIterable, Identifiable {
    case thirtyMinutes
    case oneHour
    case threeHours
    case onLoginOnly

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .thirtyMinutes:
            return "Every 30 minutes"
        case .oneHour:
            return "1 hour"
        case .threeHours:
            return "3 hours"
        case .onLoginOnly:
            return "On login only"
        }
    }

    fileprivate var timeInterval: TimeInterval? {
        switch self {
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .threeHours:
            return 3 * 60 * 60
        case .onLoginOnly:
            return nil
        }
    }
}

final class WallpaperCoordinator: ObservableObject {
    static let shared = WallpaperCoordinator()

    @Published var lightWallpapers: [URL] {
        didSet {
            normalizeCurrentWallpaper(isDark: false)
            persistState()
        }
    }

    @Published var darkWallpapers: [URL] {
        didSet {
            normalizeCurrentWallpaper(isDark: true)
            persistState()
        }
    }

    @Published private(set) var currentLightWallpaper: URL? {
        didSet {
            persistState()
        }
    }

    @Published private(set) var currentDarkWallpaper: URL? {
        didSet {
            persistState()
        }
    }

    @Published var changeWallpaperWhenAppearanceChanges: Bool {
        didSet {
            persistState()
        }
    }

    @Published var rotateWallpaper: Bool {
        didSet {
            persistState()
            configureRotationTimer()
        }
    }

    @Published var rotationInterval: WallpaperRotationInterval {
        didSet {
            persistState()
            configureRotationTimer()
        }
    }

    private let defaults: UserDefaults
    private let dockDesktopPictureDatabaseURL: URL
    private var rotationTimer: Timer?
    private var screenParametersObserver: NSObjectProtocol?
    private var screenParametersDebounceWorkItem: DispatchWorkItem?

    private enum DefaultsKey {
        static let lightWallpapers = "WallpaperCoordinator.lightWallpapers"
        static let darkWallpapers = "WallpaperCoordinator.darkWallpapers"
        // These index keys were written by earlier versions as the next wallpaper cursor.
        static let lightWallpaperIndex = "WallpaperCoordinator.lightWallpaperIndex"
        static let darkWallpaperIndex = "WallpaperCoordinator.darkWallpaperIndex"
        static let currentLightWallpaper = "WallpaperCoordinator.currentLightWallpaper"
        static let currentDarkWallpaper = "WallpaperCoordinator.currentDarkWallpaper"
        static let rotateWallpaper = "WallpaperCoordinator.rotateWallpaper"
        static let rotationInterval = "WallpaperCoordinator.rotationInterval"
        static let changeWallpaperWhenAppearanceChanges = "WallpaperCoordinator.changeWallpaperWhenAppearanceChanges"
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dockDesktopPictureDatabaseURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Dock/desktoppicture.db")

        let initialLightWallpapers = Self.loadURLs(forKey: DefaultsKey.lightWallpapers, from: defaults)
        let initialDarkWallpapers = Self.loadURLs(forKey: DefaultsKey.darkWallpapers, from: defaults)
        lightWallpapers = initialLightWallpapers
        darkWallpapers = initialDarkWallpapers
        currentLightWallpaper = Self.loadCurrentWallpaper(
            forKey: DefaultsKey.currentLightWallpaper,
            legacyIndexKey: DefaultsKey.lightWallpaperIndex,
            wallpapers: initialLightWallpapers,
            defaults: defaults
        )
        currentDarkWallpaper = Self.loadCurrentWallpaper(
            forKey: DefaultsKey.currentDarkWallpaper,
            legacyIndexKey: DefaultsKey.darkWallpaperIndex,
            wallpapers: initialDarkWallpapers,
            defaults: defaults
        )
        rotateWallpaper = defaults.bool(forKey: DefaultsKey.rotateWallpaper)
        rotationInterval = defaults.string(forKey: DefaultsKey.rotationInterval)
            .flatMap(WallpaperRotationInterval.init(rawValue:)) ?? .onLoginOnly
        changeWallpaperWhenAppearanceChanges = defaults.object(
            forKey: DefaultsKey.changeWallpaperWhenAppearanceChanges
        ) as? Bool ?? true

        normalizeCurrentWallpaper(isDark: false)
        normalizeCurrentWallpaper(isDark: true)
        persistState()
        configureRotationTimer()
        configureScreenParametersObserver()
    }

    deinit {
        if let screenParametersObserver {
            NotificationCenter.default.removeObserver(screenParametersObserver)
        }

        screenParametersDebounceWorkItem?.cancel()
        rotationTimer?.invalidate()
    }

    func applyWallpaper(isDark: Bool) {
        normalizeCurrentWallpaper(isDark: isDark)
        guard let wallpaperURL = currentWallpaper(isDark: isDark) else {
            return
        }

        guard Self.isAvailableWallpaper(wallpaperURL) else {
            print("Skipping unavailable wallpaper: \(wallpaperURL.path)")
            return
        }

        for screen in NSScreen.screens {
            guard Self.isAvailableWallpaper(wallpaperURL) else {
                print("Skipping unavailable wallpaper: \(wallpaperURL.path)")
                return
            }

            do {
                try NSWorkspace.shared.setDesktopImageURL(
                    wallpaperURL,
                    for: screen,
                    options: [:]
                )
            } catch {
                print("Failed to apply wallpaper to screen \(screen): \(error.localizedDescription)")
            }
        }

        applyWallpaperToAllSpaces(wallpaperURL)
    }

    func applyWallpaperForLaunch(isDark: Bool) {
        guard rotateWallpaper, rotationInterval == .onLoginOnly else {
            applyWallpaper(isDark: isDark)
            return
        }

        advanceAndApplyWallpaper(isDark: isDark)
    }

    func currentWallpaper(isDark: Bool) -> URL? {
        isDark ? currentDarkWallpaper : currentLightWallpaper
    }

    func selectWallpaper(_ wallpaperURL: URL, isDark: Bool) {
        let wallpapers = isDark ? darkWallpapers : lightWallpapers
        guard wallpapers.contains(wallpaperURL), Self.isAvailableWallpaper(wallpaperURL) else {
            return
        }

        if isDark {
            currentDarkWallpaper = wallpaperURL
        } else {
            currentLightWallpaper = wallpaperURL
        }
    }

    func advanceAndApplyWallpaper(isDark: Bool) {
        let wallpapers = (isDark ? darkWallpapers : lightWallpapers)
            .filter { Self.isAvailableWallpaper($0) }
        guard !wallpapers.isEmpty else {
            normalizeCurrentWallpaper(isDark: isDark)
            return
        }

        let current = currentWallpaper(isDark: isDark)
        let currentIndex = current.flatMap { wallpapers.firstIndex(of: $0) } ?? -1
        let nextIndex = (currentIndex + 1) % wallpapers.count
        selectWallpaper(wallpapers[nextIndex], isDark: isDark)
        applyWallpaper(isDark: isDark)
    }

    static func isAvailableWallpaper(_ wallpaperURL: URL) -> Bool {
        guard wallpaperURL.isFileURL,
              FileManager.default.fileExists(atPath: wallpaperURL.path),
              FileManager.default.isReadableFile(atPath: wallpaperURL.path),
              NSImage(contentsOf: wallpaperURL) != nil else {
            return false
        }

        return true
    }

    private func normalizeCurrentWallpaper(isDark: Bool) {
        let wallpapers = isDark ? darkWallpapers : lightWallpapers
        let current = currentWallpaper(isDark: isDark)
        let normalized = current.flatMap {
            wallpapers.contains($0) && Self.isAvailableWallpaper($0) ? $0 : nil
        } ?? wallpapers.first { Self.isAvailableWallpaper($0) }

        if isDark {
            currentDarkWallpaper = normalized
        } else {
            currentLightWallpaper = normalized
        }
    }

    private func persistState() {
        defaults.set(lightWallpapers.map(\.absoluteString), forKey: DefaultsKey.lightWallpapers)
        defaults.set(darkWallpapers.map(\.absoluteString), forKey: DefaultsKey.darkWallpapers)
        defaults.set(currentLightWallpaper?.absoluteString, forKey: DefaultsKey.currentLightWallpaper)
        defaults.set(currentDarkWallpaper?.absoluteString, forKey: DefaultsKey.currentDarkWallpaper)
        defaults.set(rotateWallpaper, forKey: DefaultsKey.rotateWallpaper)
        defaults.set(rotationInterval.rawValue, forKey: DefaultsKey.rotationInterval)
        defaults.set(
            changeWallpaperWhenAppearanceChanges,
            forKey: DefaultsKey.changeWallpaperWhenAppearanceChanges
        )
    }

    private func configureRotationTimer() {
        rotationTimer?.invalidate()
        rotationTimer = nil

        guard rotateWallpaper, let interval = rotationInterval.timeInterval else {
            return
        }

        rotationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.advanceAndApplyWallpaper(isDark: Self.resolveIsDarkMode())
        }
    }

    private func configureScreenParametersObserver() {
        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleScreenParametersWallpaperRefresh()
        }
    }

    private func scheduleScreenParametersWallpaperRefresh() {
        screenParametersDebounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.applyWallpaper(isDark: AppearanceMonitor.shared.isDarkMode)
        }

        screenParametersDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    private static func resolveIsDarkMode() -> Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private func applyWallpaperToAllSpaces(_ wallpaperURL: URL) {
        guard Self.isAvailableWallpaper(wallpaperURL) else {
            print("Skipping unavailable wallpaper for all Spaces: \(wallpaperURL.path)")
            return
        }

        guard FileManager.default.fileExists(atPath: dockDesktopPictureDatabaseURL.path) else {
            print("Dock desktop picture database not found at \(dockDesktopPictureDatabaseURL.path)")
            return
        }

        do {
            try updateDockDesktopPictureDatabase(wallpaperURL: wallpaperURL)
            try reloadDock()
        } catch {
            print("Failed to apply wallpaper to all Spaces: \(error.localizedDescription)")
        }
    }

    private func updateDockDesktopPictureDatabase(wallpaperURL: URL) throws {
        var database: OpaquePointer?

        guard sqlite3_open(dockDesktopPictureDatabaseURL.path, &database) == SQLITE_OK else {
            let message = database.map { sqlite3ErrorMessage($0) } ?? "Unable to open database."
            if let database {
                sqlite3_close(database)
            }
            throw WallpaperCoordinatorError.databaseOpenFailed(message)
        }

        defer {
            sqlite3_close(database)
        }

        let updateSQL = "UPDATE data SET value = ?;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(database, updateSQL, -1, &statement, nil) == SQLITE_OK else {
            throw WallpaperCoordinatorError.databaseUpdateFailed(sqlite3ErrorMessage(database))
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_bind_text(statement, 1, wallpaperURL.path, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
            throw WallpaperCoordinatorError.databaseUpdateFailed(sqlite3ErrorMessage(database))
        }

        guard Self.isAvailableWallpaper(wallpaperURL) else {
            throw WallpaperCoordinatorError.wallpaperUnavailable(wallpaperURL.path)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw WallpaperCoordinatorError.databaseUpdateFailed(sqlite3ErrorMessage(database))
        }
    }

    private func reloadDock() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw WallpaperCoordinatorError.dockReloadFailed(process.terminationStatus)
        }
    }

    private func sqlite3ErrorMessage(_ database: OpaquePointer?) -> String {
        guard let database, let errorMessage = sqlite3_errmsg(database) else {
            return "Unknown SQLite error."
        }

        return String(cString: errorMessage)
    }

    private static func loadURLs(forKey key: String, from defaults: UserDefaults) -> [URL] {
        defaults.stringArray(forKey: key)?.compactMap(URL.init(string:)) ?? []
    }

    private static func loadCurrentWallpaper(
        forKey key: String,
        legacyIndexKey: String,
        wallpapers: [URL],
        defaults: UserDefaults
    ) -> URL? {
        if let savedURLString = defaults.string(forKey: key),
           let savedURL = URL(string: savedURLString),
           wallpapers.contains(savedURL) {
            return savedURL
        }

        guard !wallpapers.isEmpty else {
            return nil
        }

        if defaults.object(forKey: key) != nil {
            return wallpapers[0]
        }

        guard defaults.object(forKey: legacyIndexKey) != nil else {
            return wallpapers[0]
        }

        let legacyNextIndex = min(max(defaults.integer(forKey: legacyIndexKey), 0), wallpapers.count - 1)
        let previousIndex = (legacyNextIndex - 1 + wallpapers.count) % wallpapers.count
        return wallpapers[previousIndex]
    }
}

private enum WallpaperCoordinatorError: LocalizedError {
    case databaseOpenFailed(String)
    case databaseUpdateFailed(String)
    case dockReloadFailed(Int32)
    case wallpaperUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .databaseOpenFailed(let message):
            return "Could not open Dock desktop picture database: \(message)"
        case .databaseUpdateFailed(let message):
            return "Could not update Dock desktop picture database: \(message)"
        case .dockReloadFailed(let status):
            return "Could not reload Dock. killall exited with status \(status)."
        case .wallpaperUnavailable(let path):
            return "Wallpaper is unavailable or unreadable: \(path)"
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
