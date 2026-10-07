//
//  DeepLinkTests.swift
//  NewsKitTests
//

import Foundation
import Testing
@testable import NewsKit

struct DeepLinkTests {

    @Test(arguments: [
        DeepLink.headlines,
        .article(URL(string: "https://example.com/story")!),
        .article(URL(string: "https://example.com/a b?x=1&y=ä#frag")!),
        .article(URL(string: "http://example.com/plain-http")!)
    ])
    func roundTrips(link: DeepLink) {
        #expect(DeepLink(url: link.url) == link)
    }

    @Test func buildsReadableArticleURL() {
        let link = DeepLink.article(URL(string: "https://example.com/story?id=1")!)

        #expect(link.url.absoluteString == "newsfeed://article?url=https://example.com/story?id%3D1")
    }

    @Test func schemeIsCaseInsensitive() {
        #expect(DeepLink(url: URL(string: "NewsFeed://headlines")!) == .headlines)
    }

    @Test(arguments: [
        "https://example.com",                          // not our scheme
        "NewsWidgetURL://link/3",                       // pre-2026 index-based widget link
        "newsfeed://unknown",
        "newsfeed://article",                           // no url parameter
        "newsfeed://article?url=",                      // empty url
        "newsfeed://article?url=javascript:alert(1)",   // only web links may be opened
        "newsfeed://article?url=file:///etc/passwd",
        "newsfeed://article?url=www.example.com/story"
    ])
    func rejectsForeignOrMalformedLinks(string: String) throws {
        let url = try #require(URL(string: string))
        #expect(DeepLink(url: url) == nil)
    }
}
