//
//  NetworkServiceTests.swift
//  NewsFeedTests
//

import Foundation
import Testing
@testable import NewsFeed

struct NetworkServiceTests {

    private let url = URL(string: "https://newsapi.org/v2/top-headlines")!

    private let validBody = Data("""
    { "articles": [ { "source": { "name": "CNN" }, "title": "Title", "url": "https://example.com", "publishedAt": "2020-11-11T21:04:00Z" } ] }
    """.utf8)

    private func httpResponse(status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    @Test func returnsArticlesForSuccessfulResponse() throws {
        let articles = try #require(NetworkService.articles(from: validBody, response: httpResponse(status: 200), error: nil))
        #expect(articles.map(\.title) == ["Title"])
    }

    @Test func returnsNilOnTransportError() {
        #expect(NetworkService.articles(from: nil, response: nil, error: URLError(.notConnectedToInternet)) == nil)
    }

    @Test(arguments: [401, 429, 500])
    func returnsNilOnHTTPErrorEvenWithDecodableBody(status: Int) {
        #expect(NetworkService.articles(from: validBody, response: httpResponse(status: status), error: nil) == nil)
    }

    @Test func returnsNilForNewsAPIErrorBody() {
        // What newsapi.org sends for a revoked or mistyped key.
        let body = Data(#"{"status":"error","code":"apiKeyInvalid","message":"Your API key is invalid"}"#.utf8)
        #expect(NetworkService.articles(from: body, response: httpResponse(status: 200), error: nil) == nil)
    }

    @Test func returnsNilWithoutData() {
        #expect(NetworkService.articles(from: nil, response: httpResponse(status: 200), error: nil) == nil)
    }
}
