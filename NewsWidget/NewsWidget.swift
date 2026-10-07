//
//  NewsWidget.swift
//  NewsWidget
//
//  Created by   admin on 19.11.2020.
//

import WidgetKit
import SwiftUI

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
            completion(Self.timeline(for: await NetworkService.loadArticles()))
        }
    }
    
    //one news article every 10 min, then a new timeline is requested
    static func timeline(for articles: [Article]?, now: Date = Date()) -> Timeline<WidgetContent> {
        let entries = (articles ?? []).prefix(6).enumerated().map { index, article in
            WidgetContent(date: Calendar.current.date(byAdding: .minute, value: 10 * index, to: now)!,
                          title: article.title,
                          description: article.description ?? "",
                          url: index)
        }
        
        guard !entries.isEmpty else {
            //request failed: keep the placeholder and retry later instead of leaving the widget without a timeline
            let retryDate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
            return Timeline(entries: [WidgetContent.placeholder], policy: .after(retryDate))
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
        
        NewsWidgetEntryView(entry: WidgetContent(date: Date(), title: "test title", description: "test description description description", url: 0))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
