//
//  HeadlinesWidget.swift
//  NewsWidget
//
//  Shared by the iOS widget extension and the watchOS widget extension (complications).
//

import AppIntents
import NewsKit
import SwiftUI
import WidgetKit

@main
struct HeadlinesWidget: Widget {

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKind.headlines, intent: HeadlinesIntent.self, provider: HeadlinesProvider()) { entry in
            HeadlinesWidgetView(entry: entry)
        }
        .configurationDisplayName("Top Headlines")
        .description("Today's top stories, a new one every ten minutes.")
        .supportedFamilies(Self.families)
    }

    private static var families: [WidgetFamily] {
        #if os(watchOS)
        [.accessoryRectangular, .accessoryInline, .accessoryCircular, .accessoryCorner]
        #else
        [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline, .accessoryCircular]
        #endif
    }
}

/// The widget has nothing to configure yet; the intent exists so the provider can use WidgetKit's async API.
nonisolated struct HeadlinesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Top Headlines"
    static let description = IntentDescription("Shows today's top stories.")
}
