//
//  HeadlineScheduleTests.swift
//  NewsKitTests
//

import Foundation
import Testing
@testable import NewsKit

struct HeadlineScheduleTests {

    private let now = novemberEleventh2020

    @Test func noArticlesNoSlots() {
        #expect(HeadlineSchedule.slots(for: [], startingAt: now).isEmpty)
    }

    @Test func firstHeadlineStartsNowThenRotatesEveryTenMinutes() {
        let articles = (1...3).map { Article.fixture("A\($0)") }

        let slots = HeadlineSchedule.slots(for: articles, startingAt: now)

        #expect(slots.map(\.article) == articles)
        #expect(slots.map(\.index) == [0, 1, 2])
        #expect(slots.map { $0.date.timeIntervalSince(now) } == [0, 600, 1200])
    }

    @Test(arguments: [5, 6, 7, 20])
    func showsAtMostSixHeadlines(count: Int) {
        let articles = (0..<count).map { Article.fixture("A\($0)") }

        let slots = HeadlineSchedule.slots(for: articles, startingAt: now)

        #expect(slots.count == min(count, 6))
        #expect(slots.map(\.article) == Array(articles.prefix(6)))
    }

    @Test func retriesFifteenMinutesAfterFailure() {
        #expect(HeadlineSchedule.retryDate(after: now) == now.addingTimeInterval(15 * 60))
    }
}
