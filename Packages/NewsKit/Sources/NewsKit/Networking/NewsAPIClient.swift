//
//  NewsAPIClient.swift
//  NewsKit
//

import Foundation
import os

public protocol NewsAPIClient: Sendable {
    func topHeadlines() async throws(NewsAPIError) -> [Article]
}

/// Talks to newsapi.org over `URLSession`.
public struct LiveNewsAPIClient: NewsAPIClient {

    private static let logger = Logger(subsystem: "NewsKit", category: "NewsAPIClient")

    private let configuration: NewsAPIConfiguration?
    private let session: URLSession

    public init(configuration: NewsAPIConfiguration? = .main, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func topHeadlines() async throws(NewsAPIError) -> [Article] {
        guard let configuration else {
            Self.logger.error("NewsAPI key is missing: get your own key at https://newsapi.org/register, copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and set NEWS_API_KEY = <your key>")
            throw .missingAPIKey
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: configuration.topHeadlinesRequest)
        } catch let error as URLError where error.code == .cancelled {
            throw .cancelled
        } catch let error as URLError {
            Self.logger.error("Failed to load news: \(error.localizedDescription)")
            throw .transport(error.code)
        } catch is CancellationError {
            throw .cancelled
        } catch {
            Self.logger.error("Failed to load news: \(error.localizedDescription)")
            throw .transport(.unknown)
        }

        return try await Self.articles(from: data, response: response)
    }

    /// `@concurrent` keeps JSON decoding off the caller's actor (usually the main actor).
    @concurrent
    static func articles(from data: Data, response: URLResponse) async throws(NewsAPIError) -> [Article] {
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            let body = try? JSONDecoder().decode(NewsAPIErrorBody.self, from: data)
            logger.error("NewsAPI responded with HTTP \(httpResponse.statusCode): \(body?.message ?? "no message")")
            throw .http(statusCode: httpResponse.statusCode, code: body?.code, message: body?.message)
        }
        do {
            return try JSONDecoder().decode(TopHeadlinesResponse.self, from: data).articles
        } catch {
            logger.error("Failed to decode news: \(error)")
            throw .invalidResponse
        }
    }
}
