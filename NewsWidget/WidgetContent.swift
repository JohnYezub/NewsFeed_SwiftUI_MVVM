//
//  WidgetContent.swift
//  NewsFeed
//
//  Created by   admin on 19.11.2020.
//


import Foundation
import SwiftUI
import WidgetKit

nonisolated struct WidgetContent: TimelineEntry {
    var date: Date
    var title: String
    var description: String?
    var url: Int
  //  var image: UIImage?
    
    static let placeholder = WidgetContent(date: Date(), title: "Today News title", description: "This is news text. It contains the beginning of some news", url: 0)
}
