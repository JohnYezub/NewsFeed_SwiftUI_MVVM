//
//  ViewModel.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import NewsKit
import SwiftUI

struct ViewModel: Identifiable {
    
    let article: Article
    
    init(article: Article) {
        self.article = article
    }
    
    /// Stable across reloads: the article URL.
    var id: Article.ID {
        article.id
    }
    
    var title: String {
        article.title
    }
    
    var description: String {
        article.description ?? ""
    }
    
    var sourceName: String {
        article.source.name
    }
    
    var urlToImage: URL? {
        article.urlToImage
    }
    
    var urlWeb: URL {
        article.url
    }
    
    var image: UIImage?
    
    /// Local date and time, or an empty string if the API sent no usable date.
    var publishedAt: String {
        article.formattedPublicationDate() ?? ""
    }
}
