//
//  NewsAPIConfigurationTests.swift
//  NewsFeedTests
//

import Foundation
import Testing
@testable import NewsFeed

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

    @Test func appInfoPlistDeclaresAPIKeyEntry() {
        // The value comes from the git-ignored Secrets.xcconfig and may be empty on CI,
        // but the Info.plist entry must exist so the build setting reaches the app.
        #expect(Bundle.main.object(forInfoDictionaryKey: NewsAPIConfiguration.infoPlistKey) is String)
    }

    @Test(arguments: ["NewsFeed/Info.plist", "NewsWidget/Info.plist", "NewsFeedWatch/Info.plist"])
    func everyTargetInfoPlistForwardsAPIKeyBuildSetting(path: String) throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: repositoryRoot.appendingPathComponent(path))
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        #expect(plist[NewsAPIConfiguration.infoPlistKey] as? String == "$(NEWS_API_KEY)")
    }
}
