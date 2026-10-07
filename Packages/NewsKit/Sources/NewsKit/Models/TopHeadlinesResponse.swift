//
//  TopHeadlinesResponse.swift
//  NewsKit
//

import Foundation

/// Body of `GET /v2/top-headlines`.
struct TopHeadlinesResponse: Decodable, Sendable {

    let articles: [Article]

    private enum CodingKeys: String, CodingKey {
        case articles
    }

    /// Articles that fail to decode are skipped, so one malformed item does not empty the whole feed.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var items = try container.nestedUnkeyedContainer(forKey: .articles)
        var articles: [Article] = []
        while !items.isAtEnd {
            if let article = try? items.decode(Article.self) {
                articles.append(article)
            } else {
                // A failed decode does not advance the container, so consume the element explicitly.
                _ = try items.decode(Skipped.self)
            }
        }
        self.articles = articles
    }

    private struct Skipped: Decodable {
        init(from decoder: any Decoder) throws {}
    }
}

/// Body newsapi.org sends with `"status": "error"`.
struct NewsAPIErrorBody: Decodable, Sendable {
    let code: String?
    let message: String?
}
