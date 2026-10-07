//
//  NewsRepository.swift
//  NewsKit
//

import Foundation

/// Source of headlines; lets view models be tested without the network.
public protocol HeadlinesProviding: Sendable {
    func topHeadlines(forceRefresh: Bool) async throws(NewsAPIError) -> [Article]
    /// The most recent headlines regardless of age, for showing something while offline.
    func lastKnownHeadlines() async -> [Article]?
}

/// Single entry point for headlines: caches the last successful response for `cacheLifetime`
/// in memory and in a `HeadlinesStore` shared with the widget, shares one in-flight request
/// between concurrent callers and cleans up the API's output.
public actor NewsRepository: HeadlinesProviding {

    /// Shared instance backed by newsapi.org and the API key from Info.plist.
    public static let shared = NewsRepository(client: LiveNewsAPIClient(), store: FileHeadlinesStore.shared)

    private let client: any NewsAPIClient
    private let store: any HeadlinesStore
    private let cacheLifetime: TimeInterval
    private let now: @Sendable () -> Date

    private var cache: HeadlinesSnapshot?
    private var inFlight: Task<Result<[Article], NewsAPIError>, Never>?
    /// Callers currently waiting on a request started by someone else.
    private(set) var joinedCallers = 0

    public init(client: any NewsAPIClient,
                store: any HeadlinesStore = InMemoryHeadlinesStore(),
                cacheLifetime: TimeInterval = 5 * 60,
                now: @escaping @Sendable () -> Date = { Date() }) {
        self.client = client
        self.store = store
        self.cacheLifetime = cacheLifetime
        self.now = now
    }

    /// Returns cached headlines while they are fresh (from memory, or from the store if another
    /// process downloaded them more recently); `forceRefresh` bypasses both caches but still joins
    /// a request that is already running. Failures are never cached.
    public func topHeadlines(forceRefresh: Bool = false) async throws(NewsAPIError) -> [Article] {
        if !forceRefresh {
            if let cache, isFresh(cache.fetchedAt) {
                return cache.articles
            }
            if let stored = await store.load(), isFresh(stored.fetchedAt) {
                cache = newer(cache, stored)
                return stored.articles
            }
        }
        if let inFlight {
            joinedCallers += 1
            defer { joinedCallers -= 1 }
            return try await inFlight.value.get()
        }

        let client = self.client
        let task = Task { () -> Result<[Article], NewsAPIError> in
            do throws(NewsAPIError) {
                return .success(Self.normalized(try await client.topHeadlines()))
            } catch {
                return .failure(error)
            }
        }
        inFlight = task
        let result = await task.value
        inFlight = nil

        if case .success(let articles) = result {
            let snapshot = HeadlinesSnapshot(articles: articles, fetchedAt: now())
            cache = snapshot
            await store.save(snapshot)
        }
        return try result.get()
    }

    public func lastKnownHeadlines() async -> [Article]? {
        cache = newer(cache, await store.load())
        return cache?.articles
    }

    private func newer(_ lhs: HeadlinesSnapshot?, _ rhs: HeadlinesSnapshot?) -> HeadlinesSnapshot? {
        guard let lhs else { return rhs }
        guard let rhs else { return lhs }
        return rhs.fetchedAt > lhs.fetchedAt ? rhs : lhs
    }

    /// A fetch time in the future (the clock was set back) is treated as stale.
    private func isFresh(_ fetchedAt: Date) -> Bool {
        let age = now().timeIntervalSince(fetchedAt)
        return age >= 0 && age < cacheLifetime
    }

    /// Drops duplicates (same URL, first one wins) and the "[Removed]" stubs newsapi.org
    /// sends for articles that were taken down.
    static func normalized(_ articles: [Article]) -> [Article] {
        var seen = Set<Article.ID>()
        return articles.filter { article in
            article.title != "[Removed]" && seen.insert(article.id).inserted
        }
    }
}
