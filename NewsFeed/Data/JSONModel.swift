//
//  JSONModel.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import Foundation

// Models are decoded off the main actor, so they opt out of the target's default MainActor isolation.
nonisolated struct JSONModel: Codable, Sendable {
    let articles: [Article]
}

nonisolated struct Article: Codable, Sendable {
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
nonisolated struct Source: Codable, Sendable {
    let id: String?
    let name: String
}
