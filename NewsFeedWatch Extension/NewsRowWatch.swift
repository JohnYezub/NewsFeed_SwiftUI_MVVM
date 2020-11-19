//
//  NewsRowWatch.swift
//  NewsFeedWatch Extension
//
//  Created by   admin on 19.11.2020.
//

import SwiftUI

struct NewsRowWatch: View {
    
    var article: ViewModel
    
    var body: some View {
        Text(article.title)
            .lineLimit(nil)
            //.font(.title2)
    }
}

struct NewsRowWatch_Previews: PreviewProvider {
    static var previews: some View {
        NewsRowWatch(article: ListViewModel().articles[0]).previewDevice("Apple Watch Series 4 - 44mm")
        
    }
}
