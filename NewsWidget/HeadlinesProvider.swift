//
//  HeadlinesProvider.swift
//  NewsWidget
//

import Foundation
import NewsKit
import SwiftUI
import WidgetKit

nonisolated struct HeadlinesEntry: TimelineEntry {
    let date: Date
    /// The story this entry is about; `nil` when nothing could be loaded yet.
    let featured: Article?
    /// Stories after `featured`, for the large widget.
    let upNext: [Article]
    /// Downscaled JPEG of `featured`'s image (iOS only; widgets cannot load images themselves).
    let thumbnail: Data?

    static let placeholder = HeadlinesEntry(
        date: .now,
        featured: Article(
            source: Article.Source(name: "News source"),
            title: "Today's top story appears here",
            description: "A short summary of the story.",
            // The placeholder uses a valid, fixed HTTPS URL literal.
            // swiftlint:disable:next force_unwrapping
            url: URL(string: "https://newsapi.org")!,
            publishedAt: .now),
        upNext: [],
        thumbnail: nil)

    static let empty = HeadlinesEntry(date: .now, featured: nil, upNext: [], thumbnail: nil)
}

// WidgetKit calls the provider off the main thread.
nonisolated struct HeadlinesProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> HeadlinesEntry {
        .placeholder
    }

    /// Must be fast: uses cached headlines when there are any instead of going to the network.
    func snapshot(for configuration: HeadlinesIntent, in context: Context) async -> HeadlinesEntry {
        if context.isPreview {
            return .placeholder
        }
        let cached = await NewsRepository.shared.lastKnownHeadlines()
        if let item = HeadlineSchedule.plan(fresh: nil, lastKnown: cached, now: .now).items.first {
            return HeadlinesEntry(date: item.date, featured: item.article, upNext: item.upNext, thumbnail: nil)
        }
        return await timeline(for: configuration, in: context).entries.first ?? .placeholder
    }

    func timeline(for configuration: HeadlinesIntent, in context: Context) async -> Timeline<HeadlinesEntry> {
        let repository = NewsRepository.shared
        let fresh = try? await repository.topHeadlines()
        // Offline: keep showing the last headlines rather than a blank widget.
        let lastKnown = fresh == nil ? await repository.lastKnownHeadlines() : nil
        let plan = HeadlineSchedule.plan(fresh: fresh, lastKnown: lastKnown, now: .now)
        let policy: TimelineReloadPolicy = plan.reloadDate.map { .after($0) } ?? .atEnd

        guard !plan.items.isEmpty else {
            return Timeline(entries: [.empty], policy: policy)
        }

        let thumbnails = await Self.thumbnails(for: plan.items.map(\.article), family: context.family)
        let entries = plan.items.map { item in
            HeadlinesEntry(
                date: item.date,
                featured: item.article,
                upNext: item.upNext,
                thumbnail: thumbnails[item.article.id])
        }
        return Timeline(entries: entries, policy: policy)
    }

    #if os(watchOS)
    func recommendations() -> [AppIntentRecommendation<HeadlinesIntent>] {
        [AppIntentRecommendation(intent: HeadlinesIntent(), description: Text("Top Headlines"))]
    }
    #endif

    private static func thumbnails(for articles: [Article], family: WidgetFamily) async -> [Article.ID: Data] {
        #if os(iOS)
        guard [.systemMedium, .systemLarge].contains(family) else { return [:] }
        return await ThumbnailLoader.thumbnails(for: articles)
        #else
        return [:]
        #endif
    }
}
