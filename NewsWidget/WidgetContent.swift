//
//  WidgetContent.swift
//  NewsFeed
//
//  Created by   admin on 19.11.2020.
//


import Foundation
import NewsKit
import WidgetKit

nonisolated struct WidgetContent: TimelineEntry {
    var date: Date
    var title: String
    var description: String?
    /// Opens the article in the app (or the headlines list for the placeholder).
    var link: DeepLink
    
    static let placeholder = WidgetContent(date: Date(), title: "Today News title", description: "This is news text. It contains the beginning of some news", link: .headlines)
}
