//
//  ContentView.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import SwiftUI

struct ContentView : View {
    
    @StateObject var model: ListViewModel = ListViewModel()
    
    var body: some View {
        
        NavigationView {
            
            List(model.articles) { article in
                
                NavigationLink(destination: NewsDetailed(article: article))
                    {
                        NewsRow(article: article)
                    }
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

