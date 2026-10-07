//
//  Article+Formatting.swift
//  NewsKit
//

import Foundation

extension Article {

    /// Publication date for display, e.g. "Nov 11, 2020 at 9:04 PM"; `nil` if the date is unknown.
    public func formattedPublicationDate(locale: Locale = .current, timeZone: TimeZone = .current) -> String? {
        guard let publishedAt else { return nil }
        var style = Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale)
        style.timeZone = timeZone
        return publishedAt.formatted(style)
    }
}
