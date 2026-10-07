//
//  Fixtures.swift
//  NewsKitTests
//

import Foundation
@testable import NewsKit

extension Article {
    static func fixture(
        _ title: String = "Title",
        url: String? = nil,
        image: String? = nil,
        publishedAt: Date? = nil
    ) -> Article {
        guard let articleURL = URL(string: url ?? "https://example.com/\(title)") else {
            preconditionFailure("Invalid article fixture URL")
        }
        return Article(
            source: Source(name: "CNN"),
            title: title,
            url: articleURL,
            urlToImage: image.flatMap { URL(string: $0) },
            publishedAt: publishedAt)
    }
}

/// 2020-11-11T21:04:00Z
let novemberEleventh2020 = Date(timeIntervalSince1970: 1_605_128_640)
