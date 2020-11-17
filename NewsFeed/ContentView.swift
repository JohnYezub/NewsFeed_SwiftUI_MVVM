//
//  ContentView.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import SwiftUI

struct ContentView : View {
    
    @StateObject var model: ArticleListViewModel = ArticleListViewModel()
    
    var body: some View {
        
        NavigationView {
            
            List(model.articles) { article in
                NewsRow(article: article)
//                NavigationLink(
//                    destination: NewsDetailed(url: article.urlWeb)) {
//                    NewsRow(article: article)
//                }
            }
            .navigationTitle(Text("News for today"))
        }
    }
    
    
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()//(model: ArticleListViewModel())
    }
}

