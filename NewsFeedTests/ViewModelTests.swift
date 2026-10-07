//
//  ViewModelTests.swift
//  NewsFeedTests
//

import Foundation
import NewsKit
import Testing
@testable import NewsFeed

struct ViewModelTests {

    private func makeArticle(description: String? = "Description",
                             publishedAt: Date? = Date(timeIntervalSince1970: 1_605_128_640)) -> Article {
        Article(source: Article.Source(id: "cnn", name: "CNN"),
                author: "Jane Doe",
                title: "Title",
                description: description,
                url: URL(string: "https://example.com/1")!,
                urlToImage: URL(string: "https://example.com/1.jpg"),
                publishedAt: publishedAt)
    }

    @Test func exposesArticleFields() {
        let viewModel = ViewModel(article: makeArticle())

        #expect(viewModel.id == URL(string: "https://example.com/1"))
        #expect(viewModel.title == "Title")
        #expect(viewModel.description == "Description")
        #expect(viewModel.sourceName == "CNN")
        #expect(viewModel.urlWeb == URL(string: "https://example.com/1"))
        #expect(viewModel.urlToImage == URL(string: "https://example.com/1.jpg"))
        #expect(viewModel.image == nil)
    }

    @Test func idIsStableAcrossReloads() {
        #expect(ViewModel(article: makeArticle()).id == ViewModel(article: makeArticle()).id)
    }

    @Test func missingDescriptionBecomesEmptyString() {
        #expect(ViewModel(article: makeArticle(description: nil)).description == "")
    }

    @Test func showsPublicationDateInLocalTime() throws {
        let article = makeArticle()
        let expected = try #require(article.formattedPublicationDate())

        #expect(ViewModel(article: article).publishedAt == expected)
    }

    @Test func unknownPublicationDateBecomesEmptyString() {
        #expect(ViewModel(article: makeArticle(publishedAt: nil)).publishedAt == "")
    }
}
