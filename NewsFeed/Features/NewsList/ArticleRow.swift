//
//  ArticleRow.swift
//  NewsFeed
//

import NewsKit
import SwiftUI

struct ArticleRow: View {

    let article: Article
    var showsImage = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)

                if let description = article.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                ArticleMetadata(article: article)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsImage, let imageURL = article.urlToImage {
                ArticleThumbnail(url: imageURL)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

/// Source and publication date.
struct ArticleMetadata: View {

    let article: Article

    var body: some View {
        HStack(spacing: 4) {
            Text(article.source.name)
                .fontWeight(.semibold)
            if let date = article.formattedPublicationDate() {
                Text("·")
                Text(date)
            }
        }
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

private struct ArticleThumbnail: View {

    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            default:
                Rectangle().fill(.quaternary)
            }
        }
        .frame(width: 96, height: 72)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    List(Article.samples) { ArticleRow(article: $0) }
        .listStyle(.plain)
}
#endif
