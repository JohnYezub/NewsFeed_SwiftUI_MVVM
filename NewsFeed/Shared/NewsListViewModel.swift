//
//  NewsListViewModel.swift
//  NewsFeed
//

import Foundation
import NewsKit
import Observation

/// Headlines screen state, shared by the iOS and watchOS apps.
@Observable
final class NewsListViewModel {

    enum State: Equatable {
        case idle
        case loading
        case loaded([Article])
        case failed(NewsAPIError)
    }

    private(set) var state: State = .idle
    /// Set when a pull-to-refresh fails while older headlines are still on screen.
    var refreshError: NewsAPIError?
    /// Navigation stack of opened articles.
    var path: [Article] = []
    /// An article from a deep link that is not in the current list; the view opens it in a browser.
    var externalArticleURL: URL?

    private let provider: any HeadlinesProviding
    private var pendingArticleURL: URL?

    init(provider: any HeadlinesProviding = NewsRepository.shared) {
        self.provider = provider
    }

    var articles: [Article] {
        if case .loaded(let articles) = state { articles } else { [] }
    }

    /// Initial load; does nothing if headlines are already loaded or loading, so it is safe in `.task`.
    func load() async {
        switch state {
        case .loading, .loaded:
            return
        case .idle, .failed:
            break
        }
        state = .loading
        do throws(NewsAPIError) {
            state = .loaded(try await provider.topHeadlines(forceRefresh: false))
        } catch .cancelled {
            // The view went away mid-load; start over next time it appears.
            state = .idle
            return
        } catch {
            state = .failed(error)
        }
        resolvePendingArticle()
    }

    /// Pull-to-refresh: keeps the current headlines on screen if the reload fails.
    func refresh() async {
        do throws(NewsAPIError) {
            state = .loaded(try await provider.topHeadlines(forceRefresh: true))
            refreshError = nil
        } catch .cancelled {
            return
        } catch {
            if case .loaded = state {
                refreshError = error
            } else {
                state = .failed(error)
            }
        }
    }

    /// Handles a URL passed to the app. Returns `false` if it is not one of our deep links.
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard let link = DeepLink(url: url) else { return false }
        switch link {
        case .headlines:
            pendingArticleURL = nil
            path = []
        case .article(let articleURL):
            pendingArticleURL = articleURL
            switch state {
            case .loaded, .failed:
                resolvePendingArticle()
            case .idle, .loading:
                break // `load()` resolves it once headlines arrive.
            }
        }
        return true
    }

    private func resolvePendingArticle() {
        guard let articleURL = pendingArticleURL else { return }
        pendingArticleURL = nil
        if let article = articles.first(where: { $0.id == articleURL }) {
            path = [article]
        } else {
            externalArticleURL = articleURL
        }
    }
}
