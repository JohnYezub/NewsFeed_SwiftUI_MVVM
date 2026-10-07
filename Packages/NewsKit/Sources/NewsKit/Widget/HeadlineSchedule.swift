//
//  HeadlineSchedule.swift
//  NewsKit
//

import Foundation

/// When the widget shows which headline: one article per `rotationInterval`,
/// at most `maximumEntries`, then WidgetKit asks for a new timeline.
public enum HeadlineSchedule {

    public static let rotationInterval: TimeInterval = 10 * 60
    public static let maximumEntries = 6
    /// How long to wait before asking again after a failed load.
    public static let retryInterval: TimeInterval = 15 * 60

    public struct Slot: Equatable, Sendable {
        public let date: Date
        /// Position of the article in the feed.
        public let index: Int
        public let article: Article
    }

    /// The first headline is shown immediately.
    public static func slots(for articles: [Article], startingAt now: Date) -> [Slot] {
        articles.prefix(maximumEntries).enumerated().map { index, article in
            Slot(date: now.addingTimeInterval(rotationInterval * Double(index)), index: index, article: article)
        }
    }

    public static func retryDate(after now: Date) -> Date {
        now.addingTimeInterval(retryInterval)
    }

    /// What a widget timeline should contain.
    public struct Plan: Equatable, Sendable {
        public struct Item: Equatable, Sendable {
            public let date: Date
            public let article: Article
            /// The stories after `article`, for layouts that list more than one.
            public let upNext: [Article]
        }

        public let items: [Item]
        /// When to ask for a new timeline; `nil` means after the last item.
        public let reloadDate: Date?
    }

    /// Fresh headlines rotate through the full schedule. Without them, cached headlines (or nothing)
    /// are shown and a reload is requested after `retryInterval`, so the widget recovers soon after
    /// the network does.
    public static func plan(fresh: [Article]?, lastKnown: [Article]?, now: Date, upNextCount: Int = 3) -> Plan {
        let isFresh = fresh?.isEmpty == false
        let articles = isFresh ? fresh ?? [] : lastKnown ?? []
        let items = slots(for: articles, startingAt: now).map { slot in
            Plan.Item(date: slot.date,
                      article: slot.article,
                      upNext: Array(articles.dropFirst(slot.index + 1).prefix(upNextCount)))
        }
        return Plan(items: items, reloadDate: isFresh ? nil : retryDate(after: now))
    }
}
