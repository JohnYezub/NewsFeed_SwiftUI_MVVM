//
//  ContentView.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import SwiftUI

struct ContentView : View {
    
    @StateObject var model: ListViewModel = ListViewModel()
    @State var linkActive: Bool = false
    @State var value: Int = 0
    
    var body: some View {
        
        NavigationView {
            
            List(model.articles) { article in
                
                
                NavigationLink(destination: NewsDetailed(article: article), isActive: $linkActive)
                    {
                        NewsRow(article: article)
                    }
            }
            .navigationTitle(Text("News for today"))
            .onOpenURL { url in
                linkActive = true
                //value = Int(url)
                print(url.pathComponents)
                print(url.lastPathComponent)
                print("Received deep link: \(url)")
            }
        }
    }
    
    
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()//(model: ArticleListViewModel())
    }
}

