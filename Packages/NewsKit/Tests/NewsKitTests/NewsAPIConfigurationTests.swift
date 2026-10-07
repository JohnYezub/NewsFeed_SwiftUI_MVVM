//
//  NewsAPIConfigurationTests.swift
//  NewsKitTests
//

import Foundation
import Testing
@testable import NewsKit

struct NewsAPIConfigurationTests {

    @Test func readsKeyFromInfoDictionary() throws {
        let configuration = try #require(NewsAPIConfiguration(infoDictionary: ["NewsAPIKey": "abc123"]))
        #expect(configuration.apiKey == "abc123")
        #expect(configuration.country == "us")
    }

    @Test func trimsWhitespaceAroundKey() throws {
        let configuration = try #require(NewsAPIConfiguration(apiKey: "  abc123\n"))
        #expect(configuration.apiKey == "abc123")
    }

    @Test(arguments: [nil, "", "   ", "\n"] as [String?])
    func rejectsMissingOrBlankKey(apiKey: String?) {
        #expect(NewsAPIConfiguration(apiKey: apiKey) == nil)
    }

    @Test func rejectsInfoDictionaryWithoutStringKey() {
        #expect(NewsAPIConfiguration(infoDictionary: nil) == nil)
        #expect(NewsAPIConfiguration(infoDictionary: [:]) == nil)
        #expect(NewsAPIConfiguration(infoDictionary: ["NewsAPIKey": 42]) == nil)
    }

    @Test func topHeadlinesURLPointsToNewsAPI() throws {
        let configuration = try #require(NewsAPIConfiguration(apiKey: "abc123", country: "gb"))
        let components = try #require(URLComponents(url: configuration.topHeadlinesURL, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "https")
        #expect(components.host == "newsapi.org")
        #expect(components.path == "/v2/top-headlines")
        #expect(components.queryItems == [URLQueryItem(name: "country", value: "gb")])
    }

    @Test func requestSendsKeyInHeaderNotInURL() throws {
        let configuration = try #require(NewsAPIConfiguration(apiKey: "abc123"))
        let request = configuration.topHeadlinesRequest
        #expect(request.value(forHTTPHeaderField: "X-Api-Key") == "abc123")
        #expect(request.url?.absoluteString.contains("abc123") == false)
    }
}
