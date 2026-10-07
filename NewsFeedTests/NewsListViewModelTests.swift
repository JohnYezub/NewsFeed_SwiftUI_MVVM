//
//  NewsListViewModelTests.swift
//  NewsFeedTests
//

import Foundation
import NewsKit
import Synchronization
import Testing
@testable import NewsFeed

struct NewsListViewModelTests {

    /// Answers with queued results and records the `forceRefresh` flag of every call.
    nonisolated final class MockHeadlines: HeadlinesProviding {
        private let results: Mutex<[Result<[Article], NewsAPIError>]>
        private let recordedCalls = Mutex<[Bool]>([])
        private let lastKnown: [Article]?

        init(_ results: Result<[Article], NewsAPIError>..., lastKnown: [Article]? = nil) {
            self.results = Mutex(results)
            self.lastKnown = lastKnown
        }

        func lastKnownHeadlines() async -> [Article]? {
            lastKnown
        }

        var calls: [Bool] { recordedCalls.withLock { $0 } }

        func topHeadlines(forceRefresh: Bool) async throws(NewsAPIError) -> [Article] {
            recordedCalls.withLock { $0.append(forceRefresh) }
            let result = results.withLock { $0.isEmpty ? .failure(.invalidResponse) : $0.removeFirst() }
            return try result.get()
        }
    }

    /// Holds every call until `open()`, so a test can act while a load is in progress.
    nonisolated final class GatedHeadlines: HeadlinesProviding {
        private let articles: [Article]
        private let state = Mutex<(started: Bool, isOpen: Bool, waiters: [CheckedContinuation<Void, Never>])>((false, false, []))

        init(_ articles: [Article]) {
            self.articles = articles
        }

        var hasStarted: Bool { state.withLock { $0.started } }

        func lastKnownHeadlines() async -> [Article]? {
            nil
        }

        func open() {
            let waiters = state.withLock { state in
                state.isOpen = true
                defer { state.waiters = [] }
                return state.waiters
            }
            waiters.forEach { $0.resume() }
        }

        func topHeadlines(forceRefresh: Bool) async throws(NewsAPIError) -> [Article] {
            await withCheckedContinuation { continuation in
                let resumeNow = state.withLock { state in
                    state.started = true
                    if !state.isOpen { state.waiters.append(continuation) }
                    return state.isOpen
                }
                if resumeNow { continuation.resume() }
            }
            return articles
        }
    }

    nonisolated private static func article(_ title: String) -> Article {
        Article(source: Article.Source(name: "CNN"), title: title, url: URL(string: "https://example.com/\(title)")!)
    }

    nonisolated private static let first = [article("A"), article("B")]
    nonisolated private static let second = [article("C")]

    /// Keeps tests away from the real WidgetCenter.
    private func makeViewModel(_ provider: any HeadlinesProviding, headlinesDidChange: @escaping () -> Void = {}) -> NewsListViewModel {
        NewsListViewModel(provider: provider, headlinesDidChange: headlinesDidChange)
    }

    private func link(to article: Article) -> URL {
        DeepLink.article(article.url).url
    }

    // MARK: - Loading

    @Test func startsIdle() {
        let viewModel = makeViewModel(MockHeadlines())

        #expect(viewModel.state == .idle)
        #expect(viewModel.articles.isEmpty)
    }

    @Test func loadPublishesHeadlines() async {
        let provider = MockHeadlines(.success(Self.first))
        let viewModel = makeViewModel(provider)

        await viewModel.load()

        #expect(viewModel.state == .loaded(Self.first))
        #expect(provider.calls == [false])
    }

    @Test func loadFailureShowsError() async {
        let viewModel = makeViewModel(MockHeadlines(.failure(.transport(.notConnectedToInternet))))

        await viewModel.load()

        #expect(viewModel.state == .failed(.transport(.notConnectedToInternet)))
    }

    @Test func loadIsIdempotentOnceLoaded() async {
        let provider = MockHeadlines(.success(Self.first), .success(Self.second))
        let viewModel = makeViewModel(provider)

        await viewModel.load()
        await viewModel.load()

        #expect(viewModel.state == .loaded(Self.first))
        #expect(provider.calls.count == 1)
    }

    @Test func loadRetriesAfterFailure() async {
        let provider = MockHeadlines(.failure(.invalidResponse), .success(Self.first))
        let viewModel = makeViewModel(provider)

        await viewModel.load()
        await viewModel.load()

        #expect(viewModel.state == .loaded(Self.first))
    }

    @Test func cancelledLoadReturnsToIdle() async {
        let viewModel = makeViewModel(MockHeadlines(.failure(.cancelled)))

        await viewModel.load()

        #expect(viewModel.state == .idle)
    }

    @Test func offlineLoadShowsLastKnownHeadlinesAndReportsError() async {
        let viewModel = makeViewModel(MockHeadlines(.failure(.transport(.notConnectedToInternet)), lastKnown: Self.first))

        await viewModel.load()

        #expect(viewModel.state == .loaded(Self.first))
        #expect(viewModel.refreshError == .transport(.notConnectedToInternet))
    }

    @Test func emptyLastKnownHeadlinesStillShowError() async {
        let viewModel = makeViewModel(MockHeadlines(.failure(.invalidResponse), lastKnown: []))

        await viewModel.load()

        #expect(viewModel.state == .failed(.invalidResponse))
        #expect(viewModel.refreshError == nil)
    }

    // MARK: - Widget reloads

    @Test func newHeadlinesAskWidgetToReload() async {
        let reloads = Mutex(0)
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first), .success(Self.second)),
                                      headlinesDidChange: { reloads.withLock { $0 += 1 } })

        await viewModel.load()
        await viewModel.refresh()

        #expect(reloads.withLock { $0 } == 2)
    }

    @Test func unchangedHeadlinesDoNotReloadWidget() async {
        let reloads = Mutex(0)
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first), .success(Self.first), .failure(.invalidResponse)),
                                      headlinesDidChange: { reloads.withLock { $0 += 1 } })

        await viewModel.load()
        await viewModel.refresh()
        await viewModel.refresh()

        #expect(reloads.withLock { $0 } == 1)
    }

    @Test func cachedFallbackDoesNotReloadWidget() async {
        let reloads = Mutex(0)
        let viewModel = makeViewModel(MockHeadlines(.failure(.transport(.timedOut)), lastKnown: Self.first),
                                      headlinesDidChange: { reloads.withLock { $0 += 1 } })

        await viewModel.load()

        #expect(reloads.withLock { $0 } == 0)
    }

    // MARK: - Refresh

    @Test func refreshForcesReloadAndReplacesHeadlines() async {
        let provider = MockHeadlines(.success(Self.first), .success(Self.second))
        let viewModel = makeViewModel(provider)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state == .loaded(Self.second))
        #expect(provider.calls == [false, true])
    }

    @Test func failedRefreshKeepsHeadlinesAndReportsError() async {
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first), .failure(.http(statusCode: 500, code: nil, message: nil))))

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state == .loaded(Self.first))
        #expect(viewModel.refreshError == .http(statusCode: 500, code: nil, message: nil))
    }

    @Test func successfulRefreshClearsPreviousRefreshError() async {
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first), .failure(.invalidResponse), .success(Self.second)))

        await viewModel.load()
        await viewModel.refresh()
        await viewModel.refresh()

        #expect(viewModel.refreshError == nil)
        #expect(viewModel.state == .loaded(Self.second))
    }

    @Test func refreshFromErrorScreenShowsNewError() async {
        let viewModel = makeViewModel(MockHeadlines(.failure(.invalidResponse), .failure(.missingAPIKey)))

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state == .failed(.missingAPIKey))
        #expect(viewModel.refreshError == nil)
    }

    @Test func cancelledRefreshChangesNothing() async {
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first), .failure(.cancelled)))

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state == .loaded(Self.first))
        #expect(viewModel.refreshError == nil)
    }

    // MARK: - Deep links

    @Test func articleLinkOpensLoadedArticle() async {
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first)))
        await viewModel.load()

        #expect(viewModel.handle(link(to: Self.first[1])))

        #expect(viewModel.path == [Self.first[1]])
        #expect(viewModel.externalArticleURL == nil)
    }

    @Test func articleLinkReceivedBeforeLoadOpensOnceLoaded() async {
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first)))

        viewModel.handle(link(to: Self.first[0]))
        #expect(viewModel.path.isEmpty)
        await viewModel.load()

        #expect(viewModel.path == [Self.first[0]])
    }

    @Test(.timeLimit(.minutes(1)))
    func articleLinkReceivedWhileLoadingOpensOnceLoaded() async {
        let provider = GatedHeadlines(Self.first)
        let viewModel = makeViewModel(provider)

        let load = Task { await viewModel.load() }
        while !provider.hasStarted { await Task.yield() }
        #expect(viewModel.state == .loading)

        viewModel.handle(link(to: Self.first[1]))
        #expect(viewModel.path.isEmpty)
        #expect(viewModel.externalArticleURL == nil)

        provider.open()
        await load.value

        #expect(viewModel.path == [Self.first[1]])
        #expect(viewModel.externalArticleURL == nil)
    }

    @Test func unknownArticleOpensInBrowser() async {
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first)))
        await viewModel.load()
        let other = Self.article("Not in the list")

        viewModel.handle(link(to: other))

        #expect(viewModel.path.isEmpty)
        #expect(viewModel.externalArticleURL == other.url)
    }

    @Test func articleLinkStillOpensWhenLoadFails() async {
        let viewModel = makeViewModel(MockHeadlines(.failure(.transport(.timedOut))))

        viewModel.handle(link(to: Self.first[0]))
        await viewModel.load()

        #expect(viewModel.externalArticleURL == Self.first[0].url)
    }

    @Test func headlinesLinkPopsToList() async {
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first)))
        await viewModel.load()
        viewModel.path = [Self.first[0]]

        #expect(viewModel.handle(DeepLink.headlines.url))

        #expect(viewModel.path.isEmpty)
    }

    @Test(arguments: ["https://example.com", "NewsWidgetURL://link/3", "newsfeed://article"])
    func ignoresForeignLinks(string: String) async {
        let viewModel = makeViewModel(MockHeadlines(.success(Self.first)))
        await viewModel.load()

        #expect(viewModel.handle(URL(string: string)!) == false)
        #expect(viewModel.path.isEmpty)
        #expect(viewModel.externalArticleURL == nil)
    }
}
