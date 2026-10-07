//
//  ListViewModel.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import Combine
import SwiftUI

final class ListViewModel: ObservableObject {
    
    typealias LoadArticles = @Sendable () async -> [Article]?
    typealias LoadImage = @Sendable (String) async -> UIImage?
    
    @Published var articles = [ViewModel]()
    
    private let loadArticles: LoadArticles
    /// `nil` skips image downloads (the watch only shows text).
    private let loadImage: LoadImage?
    
    init(autoload: Bool = true,
         loadArticles: @escaping LoadArticles = { await NetworkService.loadArticles() },
         loadImage: LoadImage? = { await ImageStore.image(from: $0) }) {
        self.loadArticles = loadArticles
        self.loadImage = loadImage
        if autoload {
            Task { await fetchData() }
        }
    }

    func fetchData() async {
        guard let articles = await loadArticles() else { return }
        self.articles = articles.map(ViewModel.init)
        await loadImages()
    }
    
    private func loadImages() async {
        guard let loadImage else { return }
        for article in articles {
            guard let urlToImage = article.urlToImage,
                  let image = await loadImage(urlToImage) else { continue }
            // The list may have been replaced while the image was loading, so look the row up again.
            if let index = articles.firstIndex(where: { $0.id == article.id }) {
                articles[index].image = image
            }
        }
    }
}
