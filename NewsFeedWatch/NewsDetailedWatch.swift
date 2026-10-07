//
//  NewsDetailedWatch.swift
//  NewsFeedWatch Extension
//
//  Created by   admin on 19.11.2020.
//

import NewsKit
import SwiftUI

struct NewsDetailedWatch: View {
    
    var article: ViewModel
    var body: some View {
        NavigationView {
                        
                Text(article.description)
                    .lineLimit(nil)
            
//                if let URL = URL(string: article.urlWeb) {
//                    Link("Read more...", destination: URL)
//                        .padding(.top)
//                }

        }
        
    }
}

struct NewsDetailedWatch_Previews: PreviewProvider {
    static var previews: some View {
        let article = Article(source: Article.Source(name: "name"), title: "Title", description: "description", url: URL(string: "https://example.com")!, publishedAt: .now)
        NewsDetailedWatch(article: ViewModel(article: article))
        
    }
}

