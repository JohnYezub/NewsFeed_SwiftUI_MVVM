//
//  ContentView.swift
//  NewsFeedWatch Extension
//
//  Created by   admin on 19.11.2020.
//

import SwiftUI

struct ContentView: View {
    
    //rows show text only, so skip image downloads on the watch
    @StateObject var model: ListViewModel = ListViewModel(loadImage: nil)
    
    var body: some View {
        NavigationView {
            
            //this is aka "TableView"
            List(model.articles) { article in
                //if we come from widget link, lets open the selected news article
                    NavigationLink(destination: NewsDetailedWatch(article: article))
                    {
                        NewsRowWatch(article: article)
                    }
                // otherwise, open normal list of articles
            }
            .navigationTitle(Text("News for today"))
    }
}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
