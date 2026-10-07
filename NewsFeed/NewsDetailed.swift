//
//  NewsDetailed.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import NewsKit
import SwiftUI

struct NewsDetailed: View {
    
    var article: ViewModel
    var body: some View {
        NavigationView {
            VStack(alignment:.leading ){
                
                if article.image != nil {
                    Image(uiImage: article.image!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                Text(article.title)
                    .lineLimit(nil)
                    .font(.title2)
                Text(article.description)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(article.sourceName)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    Text(article.publishedAt)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.top)
                
                
                Link("Read more...", destination: article.urlWeb)
                    .padding(.top)
                Spacer()
            }
            .padding()            
        }
        
    }
}

struct NewsDetailed_Previews: PreviewProvider {
    static var previews: some View {
        let article = Article(source: Article.Source(name: "name"), title: "Title", description: "description", url: URL(string: "https://example.com")!, publishedAt: .now)
        NewsDetailed(article: ViewModel(article: article))
        
    }
}

