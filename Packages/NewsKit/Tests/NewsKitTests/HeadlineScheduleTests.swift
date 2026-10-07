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

    // MARK: - Plan

    private let fresh = (1...8).map { Article.fixture("F\($0)") }
    private let cached = (1...2).map { Article.fixture("C\($0)") }

    @Test func freshHeadlinesRotateUntilTheEnd() {
        let plan = HeadlineSchedule.plan(fresh: fresh, lastKnown: cached, now: now)

        #expect(plan.items.map(\.article) == Array(fresh.prefix(6)))
        #expect(plan.reloadDate == nil)
    }

    @Test func eachItemListsTheFollowingStories() {
        let plan = HeadlineSchedule.plan(fresh: fresh, lastKnown: nil, now: now, upNextCount: 3)

        #expect(plan.items[0].upNext == Array(fresh[1...3]))
        #expect(plan.items[5].upNext == Array(fresh[6...7]))
    }

    @Test func lastItemHasNothingUpNext() {
        let plan = HeadlineSchedule.plan(fresh: Array(fresh.prefix(2)), lastKnown: nil, now: now)

        #expect(plan.items.map(\.upNext) == [[fresh[1]], []])
    }

    @Test(arguments: [nil, [Article]()])
    func fallsBackToCachedHeadlinesAndRetriesSoon(fresh: [Article]?) {
        let plan = HeadlineSchedule.plan(fresh: fresh, lastKnown: cached, now: now)

        #expect(plan.items.map(\.article) == cached)
        #expect(plan.reloadDate == now.addingTimeInterval(15 * 60))
    }

    @Test func nothingToShowRetriesSoon() {
        let plan = HeadlineSchedule.plan(fresh: nil, lastKnown: nil, now: now)

        #expect(plan.items.isEmpty)
        #expect(plan.reloadDate == now.addingTimeInterval(15 * 60))
    }
}
