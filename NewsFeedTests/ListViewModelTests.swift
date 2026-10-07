//
//  ListViewModelTests.swift
//  NewsFeedTests
//

import Foundation
import NewsKit
import Synchronization
import Testing
import UIKit
@testable import NewsFeed

struct ListViewModelTests {

    nonisolated private static func article(_ title: String, image: String?) -> Article {
        Article(source: Article.Source(name: "CNN"), title: title,
                url: URL(string: "https://example.com/\(title)")!, urlToImage: image.flatMap { URL(string: $0) })
    }

    nonisolated private static let articles = [
        article("A", image: "https://example.com/a.png"),
        article("B", image: nil),
        article("C", image: "https://example.com/c.png")
    ]

    @Test func doesNotLoadUntilAskedWhenAutoloadIsOff() async {
        let calls = Mutex(0)
        _ = ListViewModel(autoload: false, loadArticles: { calls.withLock { $0 += 1 }; return [] }, loadImage: nil)
        await Task.yield()
        #expect(calls.withLock { $0 } == 0)
    }

    @Test func fetchDataPublishesArticlesInOrder() async {
        let viewModel = ListViewModel(autoload: false, loadArticles: { Self.articles }, loadImage: nil)

        await viewModel.fetchData()

        #expect(viewModel.articles.map(\.title) == ["A", "B", "C"])
        #expect(viewModel.articles.allSatisfy { $0.image == nil })
    }

    @Test func failedLoadKeepsCurrentArticles() async {
        let viewModel = ListViewModel(autoload: false, loadArticles: { nil }, loadImage: nil)

        await viewModel.fetchData()

        #expect(viewModel.articles.isEmpty)
    }

    @Test func attachesImagesToTheirRowsAndSkipsArticlesWithoutImage() async {
        let requested = Mutex<[URL]>([])
        let viewModel = ListViewModel(autoload: false,
                                      loadArticles: { Self.articles },
                                      loadImage: { url in
                                          requested.withLock { $0.append(url) }
                                          return url.lastPathComponent == "a.png" ? UIImage(systemName: "a.circle") : nil
                                      })

        await viewModel.fetchData()

        #expect(requested.withLock { $0 }.map(\.absoluteString) == ["https://example.com/a.png", "https://example.com/c.png"])
        #expect(viewModel.articles.map { $0.image != nil } == [true, false, false])
    }
}
