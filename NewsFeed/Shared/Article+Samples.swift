//
//  Article+Samples.swift
//  NewsFeed
//

import Foundation
import NewsKit

extension Article {

    /// Placeholder rows drawn redacted while headlines load.
    nonisolated static let loadingPlaceholders: [Article] = (1...6).map { index in
        Article(source: Source(name: "News source"),
                title: "A headline that takes up roughly two lines of text",
                description: "A short summary of the story that runs for two or three lines in the list.",
                url: URL(string: "https://placeholder.invalid/\(index)")!,
                publishedAt: .now)
    }

    #if DEBUG
    nonisolated static let samples: [Article] = [
        Article(source: Source(name: "NBC News"),
                title: "Cornell faculty senate introduces no-confidence resolution",
                description: "Cornell University faculty introduced a resolution declaring a no-confidence vote in the administration.",
                url: URL(string: "https://example.com/cornell")!,
                urlToImage: URL(string: "https://picsum.photos/seed/news1/600/400"),
                publishedAt: .now.addingTimeInterval(-3600)),
        Article(source: Source(name: "CNN"),
                title: "The 14 best Prime Day Apple deals",
                description: "Our tech reviewer has tested tons of Apple gear and is separating the wheat from the chaff.",
                url: URL(string: "https://example.com/deals")!,
                urlToImage: URL(string: "https://picsum.photos/seed/news2/600/400"),
                publishedAt: .now.addingTimeInterval(-7200)),
        Article(source: Source(name: "Reuters"),
                title: "A story without an image or a description",
                url: URL(string: "https://example.com/plain")!)
    ]
    #endif
}

#if DEBUG
/// Fixed responses for previews.
nonisolated struct PreviewHeadlines: HeadlinesProviding {
    var result: Result<[Article], NewsAPIError> = .success(Article.samples)

    func topHeadlines(forceRefresh: Bool) async throws(NewsAPIError) -> [Article] {
        try result.get()
    }
}
#endif
