//
//  HeadlinesStoreTests.swift
//  NewsKitTests
//

import Foundation
import Testing
@testable import NewsKit

struct HeadlinesStoreTests {

    private let directory = URL.temporaryDirectory.appending(path: "HeadlinesStoreTests-\(UUID().uuidString)")

    private var store: FileHeadlinesStore {
        FileHeadlinesStore(fileURL: directory.appending(path: "nested/headlines.json"))
    }

    private let fullArticle = Article(source: Article.Source(id: "cnn", name: "CNN"),
                                      author: "Jane Doe",
                                      title: "Title",
                                      description: "Description",
                                      url: URL(string: "https://example.com/1")!,
                                      urlToImage: URL(string: "https://example.com/1.jpg"),
                                      publishedAt: novemberEleventh2020.addingTimeInterval(0.25))

    @Test func articleRoundTripsThroughJSON() throws {
        let articles = [fullArticle, Article.fixture("Minimal")]

        let data = try JSONEncoder().encode(articles)
        let decoded = try JSONDecoder().decode([Article].self, from: data)

        #expect(decoded == articles)
    }

    @Test func missingFileLoadsNothing() async {
        #expect(await store.load() == nil)
    }

    @Test func savedSnapshotLoadsBack() async throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshot = HeadlinesSnapshot(articles: [fullArticle, Article.fixture("B")], fetchedAt: novemberEleventh2020)

        await store.save(snapshot)

        #expect(await store.load() == snapshot)
    }

    @Test func laterSaveReplacesEarlierOne() async throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        await store.save(HeadlinesSnapshot(articles: [Article.fixture("Old")], fetchedAt: novemberEleventh2020))
        let newer = HeadlinesSnapshot(articles: [Article.fixture("New")], fetchedAt: novemberEleventh2020.addingTimeInterval(60))

        await store.save(newer)

        #expect(await store.load() == newer)
    }

    @Test func unreadableFileLoadsNothing() async throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: store.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ not json".utf8).write(to: store.fileURL)

        #expect(await store.load() == nil)
    }
}
