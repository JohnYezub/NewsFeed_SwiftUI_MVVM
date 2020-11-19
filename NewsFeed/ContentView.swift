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
                //if we come from widget link, lets open the selected news article
                if linkActive {
                    
                    NavigationLink(destination: NewsDetailed(article: model.articles[value]), isActive: $linkActive)
                    {
                        NewsRow(article: article)
                    }
                // otherwise, open normal list of articles
                } else {
                    
                NavigationLink(destination: NewsDetailed(article: article))
                    {
                        NewsRow(article: article)
                    }
                }
                                
            }
            .navigationTitle(Text("News for today"))
            
            //once the link was tapped on widget, we get the value here
            .onOpenURL { url in
                linkActive = true
                value = Int(url.lastPathComponent)!
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

