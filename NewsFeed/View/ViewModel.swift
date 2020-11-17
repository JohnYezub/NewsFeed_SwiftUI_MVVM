//
//  ViewModel.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import SwiftUI

struct ArticleViewModel: Identifiable {
    
    let id = UUID()
    
    let article: Article
    
    init(article: Article) {
        self.article = article
    }
    
    var title: String {
        return self.article.title
    }
    
    var description: String {
        return self.article.description ?? ""
    }
    
    var sourceName: String {
        return self.article.source.name
    }
    var urlToImage: String {
        return self.article.urlToImage ?? ""
    }
    
    var urlWeb: String {
        return self.article.url
    }
    
    var image: UIImage!
    
    var publishedAt: String? {
        //2020-11-11T21:04:00Z
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        df.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = df.date(from: self.article.publishedAt) {
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        } else {
            return nil
        }
    }
}

