//
//  FormattingTests.swift
//  NewsKitTests
//

import Foundation
import Testing
@testable import NewsKit

struct FormattingTests {

    @Test func formatsDateAndTimeInGivenLocaleAndTimeZone() throws {
        let article = Article.fixture(publishedAt: novemberEleventh2020)

        let timeZone = try #require(TimeZone(identifier: "UTC"))
        let text = try #require(article.formattedPublicationDate(locale: Locale(identifier: "en_US"), timeZone: timeZone))

        #expect(text.contains("Nov 11, 2020"))
        #expect(text.contains("9:04"))
    }

    @Test func usesTheGivenTimeZone() throws {
        let article = Article.fixture(publishedAt: novemberEleventh2020)

        let timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let text = try #require(article.formattedPublicationDate(locale: Locale(identifier: "en_US"), timeZone: timeZone))

        // 21:04 UTC is 06:04 the next day in Tokyo.
        #expect(text.contains("Nov 12, 2020"))
        #expect(text.contains("6:04"))
    }

    @Test func unknownDateHasNoText() {
        #expect(Article.fixture(publishedAt: nil).formattedPublicationDate() == nil)
    }
}
