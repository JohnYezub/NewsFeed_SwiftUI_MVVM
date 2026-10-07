//
//  NewsRepositoryTests.swift
//  NewsKitTests
//

import Foundation
import Synchronization
import Testing
@testable import NewsKit

struct NewsRepositoryTests {

    /// Client whose responses are queued up front; records how often it was called.
    final class MockClient: NewsAPIClient {
        private let responses: Mutex<[Result<[Article], NewsAPIError>]>
        private let callCount = Mutex(0)
        private let gate: Gate?

        init(_ responses: Result<[Article], NewsAPIError>..., gate: Gate? = nil) {
            self.responses = Mutex(responses)
            self.gate = gate
        }

        var calls: Int { callCount.withLock { $0 } }

        func topHeadlines() async throws(NewsAPIError) -> [Article] {
            callCount.withLock { $0 += 1 }
            await gate?.wait()
            let response = responses.withLock { $0.isEmpty ? .failure(.invalidResponse) : $0.removeFirst() }
            return try response.get()
        }
    }

    /// Suspends callers until `open()`.
    actor Gate {
        private var isOpen = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func wait() async {
            guard !isOpen else { return }
            await withCheckedContinuation { waiters.append($0) }
        }

        func open() {
            isOpen = true
            waiters.forEach { $0.resume() }
            waiters.removeAll()
        }
    }

    /// Manually advanced clock.
    final class Clock: Sendable {
        private let current = Mutex(novemberEleventh2020)
        var now: Date { current.withLock { $0 } }
        func advance(by interval: TimeInterval) { current.withLock { $0 += interval } }
    }

    private let first = [Article.fixture("A"), Article.fixture("B")]
    private let second = [Article.fixture("C")]

    @Test func normalizesHeadlines() async throws {
        let raw = [
            Article.fixture("A", url: "https://example.com/1"),
            Article.fixture("[Removed]", url: "https://removed.com"),
            Article.fixture("A again", url: "https://example.com/1"),
            Article.fixture("B", url: "https://example.com/2")
        ]
        let repository = NewsRepository(client: MockClient(.success(raw)))

        let articles = try await repository.topHeadlines()

        #expect(articles.map(\.title) == ["A", "B"])
    }

    @Test func servesCacheWhileFresh() async throws {
        let client = MockClient(.success(first), .success(second))
        let clock = Clock()
        let repository = NewsRepository(client: client, cacheLifetime: 60, now: { clock.now })

        _ = try await repository.topHeadlines()
        clock.advance(by: 59)
        let articles = try await repository.topHeadlines()

        #expect(articles == first)
        #expect(client.calls == 1)
    }

    @Test func reloadsOnceCacheExpires() async throws {
        let client = MockClient(.success(first), .success(second))
        let clock = Clock()
        let repository = NewsRepository(client: client, cacheLifetime: 60, now: { clock.now })

        _ = try await repository.topHeadlines()
        clock.advance(by: 60)
        let articles = try await repository.topHeadlines()

        #expect(articles == second)
        #expect(client.calls == 2)
    }

    @Test func reloadsWhenClockMovesBackwards() async throws {
        let client = MockClient(.success(first), .success(second))
        let clock = Clock()
        let repository = NewsRepository(client: client, cacheLifetime: 60, now: { clock.now })

        _ = try await repository.topHeadlines()
        clock.advance(by: -24 * 60 * 60)
        let articles = try await repository.topHeadlines()

        #expect(articles == second)
        #expect(client.calls == 2)
    }

    @Test func forceRefreshBypassesCache() async throws {
        let client = MockClient(.success(first), .success(second))
        let repository = NewsRepository(client: client)

        _ = try await repository.topHeadlines()
        let articles = try await repository.topHeadlines(forceRefresh: true)

        #expect(articles == second)
        #expect(client.calls == 2)
    }

    @Test func failuresAreThrownAndNotCached() async throws {
        let client = MockClient(.failure(.transport(.notConnectedToInternet)), .success(first))
        let repository = NewsRepository(client: client)

        await #expect(throws: NewsAPIError.transport(.notConnectedToInternet)) {
            try await repository.topHeadlines()
        }
        let articles = try await repository.topHeadlines()

        #expect(articles == first)
        #expect(client.calls == 2)
    }

    @Test func failureKeepsPreviousCache() async throws {
        let client = MockClient(.success(first), .failure(.http(statusCode: 500, code: nil, message: nil)))
        let repository = NewsRepository(client: client)

        _ = try await repository.topHeadlines()
        await #expect(throws: NewsAPIError.self) {
            try await repository.topHeadlines(forceRefresh: true)
        }
        let articles = try await repository.topHeadlines()

        #expect(articles == first)
        #expect(client.calls == 2)
    }

    // MARK: - Store

    @Test func savesDownloadedHeadlinesToStore() async throws {
        let store = InMemoryHeadlinesStore()
        let clock = Clock()
        let repository = NewsRepository(client: MockClient(.success(first)), store: store, now: { clock.now })

        _ = try await repository.topHeadlines()

        #expect(await store.load() == HeadlinesSnapshot(articles: first, fetchedAt: clock.now))
    }

    @Test func servesFreshHeadlinesFromStoreWithoutNetwork() async throws {
        let clock = Clock()
        let store = InMemoryHeadlinesStore(HeadlinesSnapshot(articles: first, fetchedAt: clock.now.addingTimeInterval(-30)))
        let client = MockClient(.success(second))
        let repository = NewsRepository(client: client, store: store, cacheLifetime: 60, now: { clock.now })

        let articles = try await repository.topHeadlines()

        #expect(articles == first)
        #expect(client.calls == 0)
    }

    @Test func staleStoreIsRefreshedFromNetwork() async throws {
        let clock = Clock()
        let store = InMemoryHeadlinesStore(HeadlinesSnapshot(articles: first, fetchedAt: clock.now.addingTimeInterval(-61)))
        let client = MockClient(.success(second))
        let repository = NewsRepository(client: client, store: store, cacheLifetime: 60, now: { clock.now })

        let articles = try await repository.topHeadlines()

        #expect(articles == second)
        #expect(client.calls == 1)
    }

    @Test func forceRefreshIgnoresFreshStore() async throws {
        let clock = Clock()
        let store = InMemoryHeadlinesStore(HeadlinesSnapshot(articles: first, fetchedAt: clock.now))
        let client = MockClient(.success(second))
        let repository = NewsRepository(client: client, store: store, now: { clock.now })

        let articles = try await repository.topHeadlines(forceRefresh: true)

        #expect(articles == second)
        #expect(client.calls == 1)
    }

    @Test func failureKeepsStoredHeadlines() async {
        let clock = Clock()
        let stored = HeadlinesSnapshot(articles: first, fetchedAt: clock.now.addingTimeInterval(-3600))
        let store = InMemoryHeadlinesStore(stored)
        let repository = NewsRepository(client: MockClient(.failure(.transport(.notConnectedToInternet))), store: store, now: { clock.now })

        await #expect(throws: NewsAPIError.transport(.notConnectedToInternet)) {
            try await repository.topHeadlines()
        }

        #expect(await store.load() == stored)
    }

    @Test func lastKnownHeadlinesReturnsStaleStoreAfterFailure() async {
        let clock = Clock()
        let store = InMemoryHeadlinesStore(HeadlinesSnapshot(articles: first, fetchedAt: clock.now.addingTimeInterval(-86_400)))
        let repository = NewsRepository(client: MockClient(.failure(.invalidResponse)), store: store, now: { clock.now })

        _ = try? await repository.topHeadlines()

        #expect(await repository.lastKnownHeadlines() == first)
    }

    @Test func lastKnownHeadlinesPrefersNewestSource() async throws {
        let clock = Clock()
        let store = InMemoryHeadlinesStore()
        let repository = NewsRepository(client: MockClient(.success(first)), store: store, now: { clock.now })
        _ = try await repository.topHeadlines()

        // Another process wrote newer headlines in the meantime.
        await store.save(HeadlinesSnapshot(articles: second, fetchedAt: clock.now.addingTimeInterval(10)))

        #expect(await repository.lastKnownHeadlines() == second)
    }

    @Test func lastKnownHeadlinesIsNilWithoutAnyData() async {
        let repository = NewsRepository(client: MockClient())

        #expect(await repository.lastKnownHeadlines() == nil)
    }

    @Test func appAndWidgetShareHeadlinesThroughFileStore() async throws {
        let directory = URL.temporaryDirectory.appending(path: "SharedStore-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appending(path: "headlines.json")
        let appClient = MockClient(.success(first))
        let widgetClient = MockClient(.success(second))
        let app = NewsRepository(client: appClient, store: FileHeadlinesStore(fileURL: fileURL))
        let widget = NewsRepository(client: widgetClient, store: FileHeadlinesStore(fileURL: fileURL))

        let appArticles = try await app.topHeadlines()
        let widgetArticles = try await widget.topHeadlines()

        #expect(widgetArticles == appArticles)
        #expect(widgetClient.calls == 0)
    }

    // MARK: - Coalescing

    @Test(.timeLimit(.minutes(1)))
    func concurrentCallersShareOneRequest() async throws {
        let gate = Gate()
        let client = MockClient(.success(first), .success(second), gate: gate)
        let repository = NewsRepository(client: client)

        async let firstCaller = repository.topHeadlines()
        while client.calls == 0 { await Task.yield() }
        // forceRefresh would start a second request if the first one were not shared.
        async let secondCaller = repository.topHeadlines(forceRefresh: true)
        while await repository.joinedCallers == 0 { await Task.yield() }
        await gate.open()

        let results = try await (firstCaller, secondCaller)
        #expect(results.0 == first)
        #expect(results.1 == first)
        #expect(client.calls == 1)
    }
}
