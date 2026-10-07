//
//  ArticleDecodingTests.swift
//  NewsFeedTests
//

import Foundation
import Testing
@testable import NewsFeed

struct ArticleDecodingTests {

    @Test func decodesTopHeadlinesResponse() throws {
        let json = """
        {
          "status": "ok",
          "totalResults": 2,
          "articles": [
            {
              "source": { "id": "cnn", "name": "CNN" },
              "author": "Jane Doe",
              "title": "First title",
              "description": "First description",
              "url": "https://example.com/1",
              "urlToImage": "https://example.com/1.jpg",
              "publishedAt": "2020-11-11T21:04:00Z",
              "content": "Body"
            },
            {
              "source": { "id": null, "name": "Reuters" },
              "author": null,
              "title": "Second title",
              "description": null,
              "url": "https://example.com/2",
              "urlToImage": null,
              "publishedAt": "2020-11-12T08:30:00Z",
              "content": null
            }
          ]
        }
        """

        let response = try JSONDecoder().decode(JSONModel.self, from: Data(json.utf8))

        #expect(response.articles.count == 2)

        let first = response.articles[0]
        #expect(first.source.id == "cnn")
        #expect(first.source.name == "CNN")
        #expect(first.author == "Jane Doe")
        #expect(first.title == "First title")
        #expect(first.description == "First description")
        #expect(first.url == "https://example.com/1")
        #expect(first.urlToImage == "https://example.com/1.jpg")
        #expect(first.publishedAt == "2020-11-11T21:04:00Z")

        let second = response.articles[1]
        #expect(second.source.id == nil)
        #expect(second.author == nil)
        #expect(second.description == nil)
        #expect(second.urlToImage == nil)
    }

    @Test func failsWhenRequiredFieldIsMissing() {
        let json = """
        { "articles": [ { "source": { "name": "CNN" }, "url": "https://example.com", "publishedAt": "2020-11-11T21:04:00Z" } ] }
        """

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(JSONModel.self, from: Data(json.utf8))
        }
    }
}
