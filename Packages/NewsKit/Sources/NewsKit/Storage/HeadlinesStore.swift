//
//  HeadlinesStore.swift
//  NewsKit
//

import Foundation
import os

/// Headlines together with the time they were downloaded.
public struct HeadlinesSnapshot: Codable, Equatable, Sendable {
    public let articles: [Article]
    public let fetchedAt: Date

    public init(articles: [Article], fetchedAt: Date) {
        self.articles = articles
        self.fetchedAt = fetchedAt
    }
}

/// Persists the last downloaded headlines so other processes (the widget) and later launches can reuse them.
public protocol HeadlinesStore: Sendable {
    func load() async -> HeadlinesSnapshot?
    func save(_ snapshot: HeadlinesSnapshot) async
}

/// Stores the snapshot as a JSON file, by default in the App Group container shared by the app and its widget.
public struct FileHeadlinesStore: HeadlinesStore {

    /// Must match the App Group in the app's and the widget's entitlements.
    public static let appGroupIdentifier = "group.EvgenyEzub.NewsFeed"

    private static let logger = Logger(subsystem: "NewsKit", category: "HeadlinesStore")

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The App Group container, or the process's own Caches directory when the entitlement is missing
    /// (e.g. unsigned simulator builds); the cache then simply isn't shared.
    public static var shared: FileHeadlinesStore {
        let directory =
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            ?? URL.cachesDirectory
        return FileHeadlinesStore(fileURL: directory.appending(path: "headlines.json"))
    }

    @concurrent
    public func load() async -> HeadlinesSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try JSONDecoder().decode(HeadlinesSnapshot.self, from: data)
        } catch {
            Self.logger.error("Ignoring unreadable headlines cache: \(error)")
            return nil
        }
    }

    @concurrent
    public func save(_ snapshot: HeadlinesSnapshot) async {
        do {
            let data = try JSONEncoder().encode(snapshot)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            // Atomic, so a widget reading at the same moment never sees a half-written file.
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Self.logger.error("Failed to save headlines cache: \(error)")
        }
    }
}

/// Keeps the snapshot in memory only; for tests and previews.
public actor InMemoryHeadlinesStore: HeadlinesStore {

    private var snapshot: HeadlinesSnapshot?

    public init(_ snapshot: HeadlinesSnapshot? = nil) {
        self.snapshot = snapshot
    }

    public func load() -> HeadlinesSnapshot? {
        snapshot
    }

    public func save(_ snapshot: HeadlinesSnapshot) {
        self.snapshot = snapshot
    }
}
