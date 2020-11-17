//
//  ListViewModel.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import SwiftUI

class ArticleListViewModel: ObservableObject {
    
    @Published var articles = [ArticleViewModel]()
    
    init() {
        fetchData()
        
    }

    private func fetchData() {
        NetworkService.loadData() { articles in
            if let articles = articles {
                self.articles = articles.map(ArticleViewModel.init)
                self.imagesData()

            }
        }
    }
    
    private func imagesData(_ index: Int = 0) {
        guard articles.count > index else { return }
        let article = articles[index]
        ImageStore.downloadImageBy(url: article.urlToImage) {
            self.articles[index].image = $0
            if self.articles[0].image != nil, index == 0 {
            }
            self.imagesData(index + 1)
        }
        
    }
}

