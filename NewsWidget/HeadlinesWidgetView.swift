//
//  HeadlinesWidgetView.swift
//  NewsWidget
//

import NewsKit
import SwiftUI
import WidgetKit

struct HeadlinesWidgetView: View {

    @Environment(\.widgetFamily) private var family
    let entry: HeadlinesEntry

    var body: some View {
        content
            .widgetURL(link.url)
            .containerBackground(.fill.tertiary, for: .widget)
    }

    private var link: DeepLink {
        entry.featured.map { .article($0.url) } ?? .headlines
    }

    @ViewBuilder
    private var content: some View {
        if let article = entry.featured {
            switch family {
            case .accessoryInline:
                Label(article.title, systemImage: "newspaper")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "newspaper.fill")
                        .font(.title3)
                        .widgetAccentable()
                }
                .accessibilityLabel(article.title)
            #if os(watchOS)
            case .accessoryCorner:
                Image(systemName: "newspaper.fill")
                    .font(.title3)
                    .widgetAccentable()
                    .widgetLabel(article.title)
            #endif
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 0) {
                    Text(article.source.name)
                        .font(.headline)
                        .widgetAccentable()
                        .lineLimit(1)
                    Text(article.title)
                        .font(.body)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            #if os(iOS)
            case .systemMedium:
                MediumHeadline(article: article, thumbnail: entry.thumbnail)
            case .systemLarge:
                LargeHeadlines(article: article, thumbnail: entry.thumbnail, upNext: entry.upNext)
            #endif
            default:
                SmallHeadline(article: article)
            }
        } else {
            switch family {
            case .accessoryInline, .accessoryCircular, .accessoryRectangular:
                Label("No headlines", systemImage: "newspaper")
            #if os(watchOS)
            case .accessoryCorner:
                Image(systemName: "newspaper")
                    .widgetLabel("No headlines")
            #endif
            default:
                VStack(spacing: 6) {
                    Image(systemName: "newspaper")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Open NewsFeed to load today's headlines.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

/// Source and relative publication time, e.g. "CNN · 2 hr. ago" (static, unlike `Text(_:style: .relative)`).
private struct SourceLine: View {

    let article: Article

    var body: some View {
        HStack(spacing: 4) {
            Text(article.source.name)
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
            if let publishedAt = article.publishedAt {
                Text("·")
                Text(publishedAt, format: .relative(presentation: .named, unitsStyle: .abbreviated))
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

private struct SmallHeadline: View {

    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SourceLine(article: article)
            Text(article.title)
                .font(.headline)
                .lineLimit(5)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if os(iOS)
private struct Thumbnail: View {

    let data: Data?

    var body: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        } else {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: "newspaper")
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)
        }
    }
}

private struct MediumHeadline: View {

    let article: Article
    let thumbnail: Data?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                SourceLine(article: article)
                Text(article.title)
                    .font(.headline)
                    .lineLimit(3)
                if let description = article.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if thumbnail != nil {
                Thumbnail(data: thumbnail)
                    .frame(width: 96, height: 96)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }
}

private struct LargeHeadlines: View {

    let article: Article
    let thumbnail: Data?
    let upNext: [Article]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if thumbnail != nil {
                Thumbnail(data: thumbnail)
                    .frame(height: 130)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 12))
            }
            SourceLine(article: article)
            Text(article.title)
                .font(thumbnail == nil ? .title3.bold() : .headline)
                .lineLimit(thumbnail == nil ? 4 : 3)

            if !upNext.isEmpty {
                Divider()
                ForEach(upNext) { next in
                    Link(destination: DeepLink.article(next.url).url) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(next.source.name)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(next.title)
                                .font(.subheadline)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}
#endif

#if os(iOS)
#Preview("Small", as: .systemSmall) {
    HeadlinesWidget()
} timeline: {
    HeadlinesEntry.placeholder
    HeadlinesEntry.empty
}

#Preview("Medium", as: .systemMedium) {
    HeadlinesWidget()
} timeline: {
    HeadlinesEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    HeadlinesWidget()
} timeline: {
    HeadlinesEntry(date: .now, featured: HeadlinesEntry.placeholder.featured, upNext: [HeadlinesEntry.placeholder.featured!], thumbnail: nil)
}

#Preview("Lock Screen", as: .accessoryRectangular) {
    HeadlinesWidget()
} timeline: {
    HeadlinesEntry.placeholder
}
#endif
