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
        var entryDate = Date()
        var entries: [WidgetContent] = []
        
        
        //we gonna refresh news article every 10 min
        //after it - generate new timeline
        
        WidgetContent.loadData { (articles) in
            if let articles = articles, articles.count >= 5 {
                                
                for i in 0...5 {
                    
                    //generate date for time line
                    entryDate = Calendar.current.date(byAdding: .minute, value: 10, to: entryDate)!
                    
                    //create entry
                    let newsEntry = WidgetContent(date: entryDate, title: articles[i].title, description: articles[i].description ?? "", url: i)
                    
                    entries.append(newsEntry)

                }
                let timeline = Timeline(entries: entries, policy: .atEnd)
                print("creates timeline with entries: \(entries.count)")
                completion(timeline)
                
            } else {
                print("Articles are zero")
            }
            
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
