//
//  ListViewModel.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import SwiftUI

class ListViewModel: ObservableObject {
    
    @Published var articles = [ViewModel]()
    
    init() {
        fetchData()
        
    }

    private func fetchData() {
        NetworkService.loadData() { articles in
            if let articles = articles {
                self.articles = articles.map(ViewModel.init)
                self.imagesData()
            }
        }
    }
    
    private func imagesData(_ index: Int = 0) {
        //print(index)
        guard articles.count > index else { return }
        let article = articles[index]
        if article.urlToImage != nil {
        ImageStore.downloadImageBy(url: article.urlToImage!) {
            self.articles[index].image = $0
            self.imagesData(index + 1)
        }
        } else {
            self.imagesData(index + 1)
        }
    }
}

