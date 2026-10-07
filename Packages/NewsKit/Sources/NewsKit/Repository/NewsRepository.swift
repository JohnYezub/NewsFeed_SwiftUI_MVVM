//
//  NewsRepository.swift
//  NewsKit
//

import Foundation

/// Single entry point for headlines: caches the last successful response for `cacheLifetime`,
/// shares one in-flight request between concurrent callers and cleans up the API's output.
public actor NewsRepository {

    /// Shared instance backed by newsapi.org and the API key from Info.plist.
    public static let shared = NewsRepository(client: LiveNewsAPIClient())

    private let client: any NewsAPIClient
    private let cacheLifetime: TimeInterval
    private let now: @Sendable () -> Date

    private var cache: (articles: [Article], fetchedAt: Date)?
    private var inFlight: Task<Result<[Article], NewsAPIError>, Never>?
    /// Callers currently waiting on a request started by someone else.
    private(set) var joinedCallers = 0

    public init(client: any NewsAPIClient,
                cacheLifetime: TimeInterval = 5 * 60,
                now: @escaping @Sendable () -> Date = { Date() }) {
        self.client = client
        self.cacheLifetime = cacheLifetime
        self.now = now
    }

    /// Returns cached headlines while they are fresh; `forceRefresh` bypasses the cache
    /// (but still joins a request that is already running). Failures are never cached.
    public func topHeadlines(forceRefresh: Bool = false) async throws(NewsAPIError) -> [Article] {
        if !forceRefresh, let cache, isFresh(cache.fetchedAt) {
            return cache.articles
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
            cache = (articles, now())
        }
        return try result.get()
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
