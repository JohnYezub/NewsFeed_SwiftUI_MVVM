//
//  NetworkServiceTests.swift
//  NewsFeedTests
//

import Foundation
import Testing
import UIKit
@testable import NewsFeed

@Suite(.serialized)
struct NetworkServiceTests {

    private let configuration = NewsAPIConfiguration(apiKey: "test-key")

    private let validBody = Data("""
    { "articles": [ { "source": { "name": "CNN" }, "title": "Title", "url": "https://example.com", "publishedAt": "2020-11-11T21:04:00Z" } ] }
    """.utf8)

    // MARK: - loadArticles

    @Test func loadsArticlesAndSendsKeyInHeader() async throws {
        let body = validBody
        let recorder = RequestRecorder()
        let session = StubURLProtocol.makeSession { request in
            recorder.record(request)
            return (StubURLProtocol.response(for: request), body)
        }

        let articles = try #require(await NetworkService.loadArticles(configuration: configuration, session: session))
        #expect(articles.map(\.title) == ["Title"])

        let request = try #require(recorder.requests.only)
        #expect(request.value(forHTTPHeaderField: "X-Api-Key") == "test-key")
        #expect(request.url?.path == "/v2/top-headlines")
    }

    @Test func returnsNilWithoutConfiguration() async {
        let recorder = RequestRecorder()
        let session = StubURLProtocol.makeSession { request in
            recorder.record(request)
            throw URLError(.cancelled)
        }

        #expect(await NetworkService.loadArticles(configuration: nil, session: session) == nil)
        #expect(recorder.requests.isEmpty, "No request may be sent without an API key")
    }

    @Test func returnsNilOnTransportError() async {
        let session = StubURLProtocol.makeSession { _ in throw URLError(.notConnectedToInternet) }

        #expect(await NetworkService.loadArticles(configuration: configuration, session: session) == nil)
    }

    @Test func returnsNilForInvalidKeyResponse() async {
        // What newsapi.org sends for a revoked or mistyped key.
        let body = Data(#"{"status":"error","code":"apiKeyInvalid","message":"Your API key is invalid"}"#.utf8)
        let session = StubURLProtocol.makeSession { request in
            (StubURLProtocol.response(status: 401, for: request), body)
        }

        #expect(await NetworkService.loadArticles(configuration: configuration, session: session) == nil)
    }

    // MARK: - articles(from:response:)

    private func httpResponse(status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://newsapi.org")!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    @Test(arguments: [401, 429, 500])
    func rejectsHTTPErrorEvenWithDecodableBody(status: Int) {
        #expect(NetworkService.articles(from: validBody, response: httpResponse(status: status)) == nil)
    }

    @Test func rejectsErrorBodyWithSuccessStatus() {
        let body = Data(#"{"status":"error","code":"apiKeyInvalid"}"#.utf8)
        #expect(NetworkService.articles(from: body, response: httpResponse(status: 200)) == nil)
    }

    // MARK: - ImageStore

    @Test func loadsImage() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let png = try #require(UIGraphicsImageRenderer(size: CGSize(width: 2, height: 3), format: format).image { _ in }.pngData())
        let session = StubURLProtocol.makeSession { request in (StubURLProtocol.response(for: request), png) }

        let image = try #require(await ImageStore.image(from: "https://example.com/a.png", session: session))
        #expect(image.size == CGSize(width: 2, height: 3))
    }

    @Test func returnsNilForNonImageData() async {
        let session = StubURLProtocol.makeSession { request in (StubURLProtocol.response(for: request), Data("not an image".utf8)) }

        #expect(await ImageStore.image(from: "https://example.com/a.png", session: session) == nil)
    }

    @Test func returnsNilForInvalidImageURL() async {
        #expect(await ImageStore.image(from: "") == nil)
    }
}

private extension Array {
    /// The single element, or `nil` if the array is empty or has several elements.
    var only: Element? { count == 1 ? first : nil }
}
