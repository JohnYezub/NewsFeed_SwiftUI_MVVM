//
//  NewsDetailedWatch.swift
//  NewsFeedWatch Extension
//
//  Created by   admin on 19.11.2020.
//

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
        let article = Article(source: Source(id: nil, name: "name"), author: nil, title: "Title", description: "description", url: "http://google.com", urlToImage: nil, publishedAt: "14:52")
        NewsDetailedWatch(article: ViewModel(article: article))
        
    }
}

