//
//  NewsListView.swift
//  NewsFeed
//

import NewsKit
import SwiftUI

struct NewsListView: View {

    /// Owned by the App, so it is created once rather than on every re-initialization of this view.
    @Bindable var viewModel: NewsListViewModel

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            content
                .navigationTitle("News for today")
                .navigationDestination(for: Article.self) { article in
                    ArticleDetailView(article: article)
                }
        }
        .task { await viewModel.load() }
        .onOpenURL { viewModel.handle($0) }
        .sheet(item: $viewModel.externalArticleURL.identified) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        .alert(viewModel.refreshError?.title ?? "", isPresented: $viewModel.refreshError.isPresent()) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.refreshError?.message ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            List(Article.loadingPlaceholders) { article in
                ArticleRow(article: article, showsImage: false)
            }
            .listStyle(.plain)
            .redacted(reason: .placeholder)
            .allowsHitTesting(false)
            .accessibilityLabel("Loading headlines")

        case .loaded(let articles) where articles.isEmpty:
            ContentUnavailableView {
                Label("No headlines", systemImage: "newspaper")
            } description: {
                Text("There are no top stories right now.")
            } actions: {
                Button("Refresh") { Task { await viewModel.refresh() } }
            }

        case .loaded(let articles):
            List(articles) { article in
                NavigationLink(value: article) {
                    ArticleRow(article: article)
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.refresh() }

        case .failed(let error):
            ContentUnavailableView {
                Label(error.title, systemImage: error.systemImage)
            } description: {
                Text(error.message)
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

/// Lets an optional URL drive `.sheet(item:)`.
struct IdentifiedURL: Identifiable {
    let url: URL
    var id: URL { url }
}

extension Binding where Value == URL? {
    var identified: Binding<IdentifiedURL?> {
        Binding<IdentifiedURL?>(
            get: { wrappedValue.map(IdentifiedURL.init) },
            set: { wrappedValue = $0?.url }
        )
    }
}

extension Binding {
    /// `true` while the optional holds a value; setting `false` clears it.
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
}

#if DEBUG
#Preview("Loaded") {
    NewsListView(viewModel: NewsListViewModel(provider: PreviewHeadlines()))
}

#Preview("Empty") {
    NewsListView(viewModel: NewsListViewModel(provider: PreviewHeadlines(result: .success([]))))
}

#Preview("Offline") {
    NewsListView(viewModel: NewsListViewModel(provider: PreviewHeadlines(result: .failure(.transport(.notConnectedToInternet)))))
}
#endif
