//
//  NewsWidget.swift
//  NewsWidget
//
//  Created by   admin on 19.11.2020.
//

import NewsKit
import SwiftUI
import WidgetKit

// WidgetKit calls the provider off the main thread.
nonisolated struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetContent {
        //SimpleEntry(date: Date())
        WidgetContent.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetContent) -> ()) {
        //let entry = SimpleEntry(date: Date())
        completion(WidgetContent.placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let completion = WidgetKitCompletion(completion)
        Task {
            completion(Self.timeline(for: try? await NewsRepository.shared.topHeadlines()))
        }
    }
    
    static func timeline(for articles: [Article]?, now: Date = Date()) -> Timeline<WidgetContent> {
        let entries = HeadlineSchedule.slots(for: articles ?? [], startingAt: now).map { slot in
            WidgetContent(date: slot.date,
                          title: slot.article.title,
                          description: slot.article.description ?? "",
                          link: .article(slot.article.url))
        }
        
        guard !entries.isEmpty else {
            //request failed: keep the placeholder and retry later instead of leaving the widget without a timeline
            return Timeline(entries: [WidgetContent.placeholder], policy: .after(HeadlineSchedule.retryDate(after: now)))
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

/// WidgetKit accepts timeline completions from any thread, but the SDK does not mark them `@Sendable`.
/// This wrapper lets the completion be handed to a `Task`.
private nonisolated struct WidgetKitCompletion<Value>: @unchecked Sendable {
    private let completion: (Value) -> Void

    init(_ completion: @escaping (Value) -> Void) {
        self.completion = completion
    }

    func callAsFunction(_ value: Value) {
        completion(value)
    }
}

@main
struct NewsWidget: Widget {
    let kind: String = "NewsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct NewsWidget_Previews: PreviewProvider {
    static var previews: some View {
        
        NewsWidgetEntryView(entry: WidgetContent.placeholder)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
