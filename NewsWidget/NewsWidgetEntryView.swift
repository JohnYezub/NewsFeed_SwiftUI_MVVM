//
//  NewsWidgetEntryView.swift
//  NewsFeed
//
//  Created by   admin on 19.11.2020.
//

import SwiftUI
import WidgetKit

struct NewsWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: WidgetContent
    
    var body: some View {
        content
            //required since iOS 17, otherwise the system shows "Please adopt containerBackground API"
            .containerBackground(Color("WidgetBackground"), for: .widget)
    }
    
    @ViewBuilder
    private var content: some View {
        switch widgetFamily {
        case .systemSmall:
            VStack {
                Text(entry.title)
                    .font(.subheadline)
                    .lineLimit(nil)
                    .widgetURL(URL(string:"NewsWidgetURL://link/\(entry.url)")!)
            }
        default:
            VStack {
                //it doesnt matter how our link looks like, the important thing is to send news article id/number
                Link(destination: URL(string:"NewsWidgetURL://link/\(entry.url)")!)  {
                    HStack {
                        Text(entry.title)
                            .font(.title3)
                            .lineLimit(nil)
                            .padding(.bottom, 10)
                    }
                }
                Text(entry.description ?? "")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .lineLimit(nil)
            }
        }
    }
    
}

struct NewsWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let w = WidgetContent(date: Date(), title: "test title", description: "test description description description", url: 0)
        
        NewsWidgetEntryView(entry: w).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
