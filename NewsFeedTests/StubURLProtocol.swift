//
//  StubURLProtocol.swift
//  NewsFeedTests
//

import Foundation
import Synchronization

/// Answers every request of a stubbed `URLSession` with a canned response.
/// There is a single global handler, so suites that use it must be `.serialized`.
nonisolated final class StubURLProtocol: URLProtocol {

    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let handler = Mutex<Handler?>(nil)

    static func makeSession(handler: @escaping Handler) -> URLSession {
        self.handler.withLock { $0 = handler }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func response(status: Int = 200, for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler.withLock({ $0 }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Records the requests a stubbed session sends, so tests can assert on them after the call returns.
nonisolated final class RequestRecorder: Sendable {

    private let storage = Mutex<[URLRequest]>([])

    var requests: [URLRequest] { storage.withLock { $0 } }

    func record(_ request: URLRequest) {
        storage.withLock { $0.append(request) }
    }
}
