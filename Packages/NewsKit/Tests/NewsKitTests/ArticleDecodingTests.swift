//
//  ArticleDecodingTests.swift
//  NewsKitTests
//

import Foundation
import Testing
@testable import NewsKit

struct ArticleDecodingTests {

    private func decode(_ json: String) throws -> [Article] {
        try JSONDecoder().decode(TopHeadlinesResponse.self, from: Data(json.utf8)).articles
    }

    @Test func decodesAllFields() throws {
        let articles = try decode(
            """
            { "status": "ok", "totalResults": 1, "articles": [ {
                "source": { "id": "cnn", "name": "CNN" },
                "author": "Jane Doe",
                "title": "Title",
                "description": "Description",
                "url": "https://example.com/1",
                "urlToImage": "https://example.com/1.jpg",
                "publishedAt": "2020-11-11T21:04:00Z",
                "content": "Body"
            } ] }
            """)

        let article = try #require(articles.first)
        #expect(article.source == Article.Source(id: "cnn", name: "CNN"))
        #expect(article.author == "Jane Doe")
        #expect(article.title == "Title")
        #expect(article.description == "Description")
        #expect(article.url == URL(string: "https://example.com/1"))
        #expect(article.id == article.url)
        #expect(article.urlToImage == URL(string: "https://example.com/1.jpg"))
        #expect(article.publishedAt == novemberEleventh2020)
    }

    @Test func optionalFieldsMayBeNullOrMissing() throws {
        let articles = try decode(
            """
            { "articles": [
                { "source": { "id": null, "name": "Reuters" }, "author": null, "title": "A", "description": null,
                  "url": "https://example.com/a", "urlToImage": null, "publishedAt": null },
                { "source": { "name": "Reuters" }, "title": "B", "url": "https://example.com/b" }
            ] }
            """)

        #expect(articles.map(\.title) == ["A", "B"])
        #expect(articles.allSatisfy { $0.source.id == nil && $0.author == nil && $0.description == nil })
        #expect(articles.allSatisfy { $0.urlToImage == nil && $0.publishedAt == nil })
    }

    @Test func parsesFractionalSeconds() throws {
        let articles = try decode(
            """
            { "articles": [ { "source": { "name": "CNN" }, "title": "A", "url": "https://example.com/a",
                              "publishedAt": "2020-11-11T21:04:00.250Z" } ] }
            """)

        #expect(articles.first?.publishedAt == novemberEleventh2020.addingTimeInterval(0.25))
    }

    @Test func malformedOptionalFieldsBecomeNil() throws {
        let articles = try decode(
            """
            { "articles": [ { "source": { "name": "CNN" }, "title": "A", "url": "https://example.com/a",
                              "urlToImage": "data:image/png;base64,AAAA", "publishedAt": "yesterday" } ] }
            """)

        let article = try #require(articles.first)
        #expect(article.urlToImage == nil)
        #expect(article.publishedAt == nil)
    }

    @Test func skipsArticlesMissingRequiredFieldsAndKeepsTheRestInOrder() throws {
        let articles = try decode(
            """
            { "articles": [
                { "source": { "name": "CNN" }, "title": "First", "url": "https://example.com/1" },
                { "source": { "name": "CNN" }, "url": "https://example.com/no-title" },
                { "source": { "name": "CNN" }, "title": "No URL" },
                { "source": { "name": "CNN" }, "title": "Bad URL", "url": "" },
                { "source": { "name": "CNN" }, "title": "No scheme", "url": "www.example.com/story" },
                { "source": { "name": "CNN" }, "title": "Not a web link", "url": "ftp://example.com/story" },
                { "source": { "name": "CNN" }, "title": "No host", "url": "https:///story" },
                { "title": "No source", "url": "https://example.com/no-source" },
                { "source": { "name": "CNN" }, "title": "Last", "url": "https://example.com/2" }
            ] }
            """)

        #expect(articles.map(\.title) == ["First", "Last"])
    }

    @Test func skipsNullAndNonObjectElements() throws {
        let articles = try decode(
            """
            { "articles": [ null, 42, "text", [], { "source": { "name": "CNN" }, "title": "Valid", "url": "https://example.com/1" } ] }
            """)

        #expect(articles.map(\.title) == ["Valid"])
    }

    @Test func failsWithoutArticlesArray() {
        #expect(throws: DecodingError.self) {
            try decode(#"{ "status": "error", "code": "apiKeyInvalid" }"#)
        }
    }
}
