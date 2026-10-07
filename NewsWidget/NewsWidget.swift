//
//  NewsWidget.swift
//  NewsWidget
//
//  Created by   admin on 19.11.2020.
//

import WidgetKit
import SwiftUI

let defaultContent = WidgetContent(date: Date(),title: "Today News title", description: "This is news text. It contains the beginning of some news", url: 0)

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetContent {
        //SimpleEntry(date: Date())
        defaultContent
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetContent) -> ()) {
        //let entry = SimpleEntry(date: Date())
        completion(defaultContent)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        //one news article every 10 min, then a new timeline is requested
        NetworkService.loadData { articles in
            let now = Date()
            let entries = (articles ?? []).prefix(6).enumerated().map { index, article in
                WidgetContent(date: Calendar.current.date(byAdding: .minute, value: 10 * index, to: now)!,
                              title: article.title,
                              description: article.description ?? "",
                              url: index)
            }
            
            guard !entries.isEmpty else {
                //request failed: keep the placeholder and retry later instead of leaving the widget without a timeline
                let retryDate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
                completion(Timeline(entries: [defaultContent], policy: .after(retryDate)))
                return
            }
            completion(Timeline(entries: entries, policy: .atEnd))
        }
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
