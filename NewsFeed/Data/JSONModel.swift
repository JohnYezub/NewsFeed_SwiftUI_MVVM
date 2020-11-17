//
//  JSONModel.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import Foundation
struct JSONModel: Codable {
    let articles: [Article]
}

struct Article: Codable {
    let source: Source
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
   // let content: String?
    
}
// MARK: - Source
struct Source: Codable {
    let id: String?
    let name: String
}
