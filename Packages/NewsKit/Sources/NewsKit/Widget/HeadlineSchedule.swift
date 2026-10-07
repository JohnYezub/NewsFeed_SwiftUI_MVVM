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
}
