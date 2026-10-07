//
//  NewsWidgetEntryView.swift
//  NewsFeed
//
//  Created by   admin on 19.11.2020.
//

import NewsKit
import SwiftUI
import WidgetKit

struct NewsWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: WidgetContent
    
    var body: some View {
        content
            .widgetURL(entry.link.url)
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
            }
        default:
            VStack {
                Text(entry.title)
                    .font(.title3)
                    .lineLimit(nil)
                    .padding(.bottom, 10)
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
        NewsWidgetEntryView(entry: WidgetContent.placeholder).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
