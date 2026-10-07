//
//  WatchNewsListView.swift
//  NewsFeedWatch
//

import NewsKit
import SwiftUI

struct WatchNewsListView: View {

    /// Owned by the App, so it is created once rather than on every re-initialization of this view.
    @Bindable var viewModel: NewsListViewModel

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            content
                .navigationTitle("Headlines")
                .navigationDestination(for: Article.self) { article in
                    WatchArticleDetailView(article: article)
                }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()

        case .loaded(let articles) where articles.isEmpty:
            ContentUnavailableView("No headlines", systemImage: "newspaper")

        case .loaded(let articles):
            List(articles) { article in
                NavigationLink(value: article) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.title)
                            .font(.headline)
                            .lineLimit(4)
                        Text(article.source.name)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .refreshable { await viewModel.refresh() }

        case .failed(let error):
            ScrollView {
                VStack(spacing: 8) {
                    Image(systemName: error.systemImage)
                        .font(.title2)
                    Text(error.title)
                        .font(.headline)
                    Text(error.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Try Again") { Task { await viewModel.load() } }
                }
                .multilineTextAlignment(.center)
            }
        }
    }
}

#if DEBUG
#Preview {
    WatchNewsListView(viewModel: NewsListViewModel(provider: PreviewHeadlines()))
}
#endif
