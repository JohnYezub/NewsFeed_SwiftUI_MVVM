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
        switch widgetFamily {
        case .systemSmall:
            VStack {
                Text(entry.title)
                    .font(.subheadline)
                    .lineLimit(nil)
            }
            .padding()
        default:
            VStack {
                Link(destination: URL(string:"NewsWidgetURL://link/\(entry.url)")!)  {
                    HStack {
                        Text(entry.title)
                            .font(.title3)
                            .lineLimit(nil)
                            .padding(.bottom, 10)
                        
                        //                    if entry.image != nil {
                        //                        Image(uiImage: entry.image!)
                        //                            .resizable()
                        //                            .aspectRatio(contentMode: .fit)
                        //                    } else {
                        //                        Image("newspic")
                        //                            .resizable()
                        //                            .aspectRatio(contentMode: .fit)
                        //                    }
                    }
                }
                //.widgetURL(NewsWidgetEntryView.deeplinkURL)
                // Link(destination: URL(string:entry.url!)!) {
                //             Text("Link 1")
                //         }
                Text(entry.description ?? "")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .lineLimit(nil)
            }
            .padding()
        }
    }
    
}

struct NewsWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let w = WidgetContent(date: Date(), title: "test title", description: "test description description description", url: 0)
        
        NewsWidgetEntryView(entry: w).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
