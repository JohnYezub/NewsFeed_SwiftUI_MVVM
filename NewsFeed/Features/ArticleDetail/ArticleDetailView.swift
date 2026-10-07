//
//  ArticleDetailView.swift
//  NewsFeed
//

import NewsKit
import SwiftUI

struct ArticleDetailView: View {

    let article: Article

    @State private var isReading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageURL = article.urlToImage {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                            .aspectRatio(3 / 2, contentMode: .fit)
                    }
                    .clipShape(.rect(cornerRadius: 12))
                    .accessibilityHidden(true)
                }

                Text(article.title)
                    .font(.title2.bold())

                ArticleMetadata(article: article)
                    .font(.subheadline)

                if let description = article.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                }

                Button {
                    isReading = true
                } label: {
                    Label("Read full article", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(item: article.url, subject: Text(article.title))
        }
        .sheet(isPresented: $isReading) {
            SafariView(url: article.url)
                .ignoresSafeArea()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ArticleDetailView(article: Article.samples[0])
    }
}
#endif
