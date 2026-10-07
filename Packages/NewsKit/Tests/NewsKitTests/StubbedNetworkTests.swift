//
//  StubbedNetworkTests.swift
//  NewsKitTests
//

import Foundation
import Testing
@testable import NewsKit

/// Every suite in here shares `StubURLProtocol`'s single handler, so they run one test at a time.
@Suite(.serialized)
struct StubbedNetworkTests {}

extension StubbedNetworkTests {

    struct LiveNewsAPIClientTests {

        private let configuration = NewsAPIConfiguration(apiKey: "test-key")

        private let validBody = Data("""
        { "articles": [ { "source": { "name": "CNN" }, "title": "Title", "url": "https://example.com", "publishedAt": "2020-11-11T21:04:00Z" } ] }
        """.utf8)

        @Test func loadsArticlesAndSendsKeyInHeader() async throws {
            let body = validBody
            let recorder = RequestRecorder()
            let session = StubURLProtocol.makeSession { request in
                recorder.record(request)
                return (StubURLProtocol.response(for: request), body)
            }

            let articles = try await LiveNewsAPIClient(configuration: configuration, session: session).topHeadlines()

            #expect(articles.map(\.title) == ["Title"])
            let request = try #require(recorder.requests.only)
            #expect(request.value(forHTTPHeaderField: "X-Api-Key") == "test-key")
            #expect(request.url?.path == "/v2/top-headlines")
        }

        @Test func throwsMissingAPIKeyWithoutSendingARequest() async {
            let recorder = RequestRecorder()
            let session = StubURLProtocol.makeSession { request in
                recorder.record(request)
                throw URLError(.cancelled)
            }

            await #expect(throws: NewsAPIError.missingAPIKey) {
                try await LiveNewsAPIClient(configuration: nil, session: session).topHeadlines()
            }
            #expect(recorder.requests.isEmpty)
        }

        @Test func mapsTransportErrors() async {
            let session = StubURLProtocol.makeSession { _ in throw URLError(.notConnectedToInternet) }

            await #expect(throws: NewsAPIError.transport(.notConnectedToInternet)) {
                try await LiveNewsAPIClient(configuration: configuration, session: session).topHeadlines()
            }
        }

        @Test func mapsCancellation() async {
            let session = StubURLProtocol.makeSession { _ in throw URLError(.cancelled) }

            await #expect(throws: NewsAPIError.cancelled) {
                try await LiveNewsAPIClient(configuration: configuration, session: session).topHeadlines()
            }
        }

        @Test func mapsHTTPErrorWithNewsAPIErrorBody() async {
            // What newsapi.org sends for a revoked or mistyped key.
            let body = Data(#"{"status":"error","code":"apiKeyInvalid","message":"Your API key is invalid"}"#.utf8)
            let session = StubURLProtocol.makeSession { request in
                (StubURLProtocol.response(status: 401, for: request), body)
            }

            await #expect(throws: NewsAPIError.http(statusCode: 401, code: "apiKeyInvalid", message: "Your API key is invalid")) {
                try await LiveNewsAPIClient(configuration: configuration, session: session).topHeadlines()
            }
        }

        @Test func mapsHTTPErrorWithoutBody() async {
            let session = StubURLProtocol.makeSession { request in
                (StubURLProtocol.response(status: 503, for: request), Data())
            }

            await #expect(throws: NewsAPIError.http(statusCode: 503, code: nil, message: nil)) {
                try await LiveNewsAPIClient(configuration: configuration, session: session).topHeadlines()
            }
        }

        @Test func mapsUndecodableBodyToInvalidResponse() async {
            let session = StubURLProtocol.makeSession { request in
                (StubURLProtocol.response(for: request), Data("<html>".utf8))
            }

            await #expect(throws: NewsAPIError.invalidResponse) {
                try await LiveNewsAPIClient(configuration: configuration, session: session).topHeadlines()
            }
        }
    }
}

private extension Array {
    /// The single element, or `nil` if the array is empty or has several elements.
    var only: Element? { count == 1 ? first : nil }
}
