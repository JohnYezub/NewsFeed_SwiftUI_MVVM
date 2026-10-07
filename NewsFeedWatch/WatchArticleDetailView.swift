//
//  WatchArticleDetailView.swift
//  NewsFeedWatch
//

import NewsKit
import SwiftUI

struct WatchArticleDetailView: View {

    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                Text([article.source.name, article.formattedPublicationDate()].compactMap { $0 }.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let description = article.description, !description.isEmpty {
                    Text(description)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    WatchArticleDetailView(article: Article.samples[0])
}
#endif
