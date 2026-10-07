//
//  NewsAPIErrorPresentationTests.swift
//  NewsFeedTests
//

import Foundation
import NewsKit
import Testing
@testable import NewsFeed

struct NewsAPIErrorPresentationTests {

    nonisolated static let allErrors: [NewsAPIError] = [
        .missingAPIKey,
        .transport(.notConnectedToInternet),
        .transport(.timedOut),
        .http(statusCode: 401, code: "apiKeyInvalid", message: "Your API key is invalid"),
        .http(statusCode: 429, code: "rateLimited", message: nil),
        .http(statusCode: 500, code: nil, message: nil),
        .invalidResponse,
        .cancelled
    ]

    @Test(arguments: allErrors)
    func everyErrorHasTitleMessageAndIcon(error: NewsAPIError) {
        #expect(!error.title.isEmpty)
        #expect(!error.message.isEmpty)
        #expect(!error.systemImage.isEmpty)
    }

    @Test func keyProblemsPointToTheSecretsFile() {
        #expect(NewsAPIError.missingAPIKey.message.contains("Secrets.xcconfig"))
        #expect(NewsAPIError.http(statusCode: 401, code: nil, message: nil).message.contains("Secrets.xcconfig"))
    }

    @Test func offlineIsToldApartFromOtherTransportErrors() {
        #expect(NewsAPIError.transport(.notConnectedToInternet).title == "You're offline")
        #expect(NewsAPIError.transport(.notConnectedToInternet).systemImage == "wifi.slash")
        #expect(NewsAPIError.transport(.timedOut).title != "You're offline")
    }

    @Test func serverMessageIsShownForOtherHTTPErrors() {
        let error = NewsAPIError.http(statusCode: 400, code: "parameterInvalid", message: "The country parameter is invalid")
        #expect(error.message == "The country parameter is invalid")
        #expect(NewsAPIError.http(statusCode: 503, code: nil, message: nil).message.contains("503"))
    }
}
