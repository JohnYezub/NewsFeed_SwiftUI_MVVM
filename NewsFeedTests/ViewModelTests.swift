//
//  ViewModelTests.swift
//  NewsFeedTests
//

import Foundation
import Testing
@testable import NewsFeed

struct ViewModelTests {

    private func makeArticle(description: String? = "Description",
                             urlToImage: String? = "https://example.com/1.jpg",
                             publishedAt: String = "2020-11-11T21:04:00Z") -> Article {
        Article(source: Source(id: "cnn", name: "CNN"),
                author: "Jane Doe",
                title: "Title",
                description: description,
                url: "https://example.com/1",
                urlToImage: urlToImage,
                publishedAt: publishedAt)
    }

    @Test func exposesArticleFields() {
        let viewModel = ViewModel(article: makeArticle())

        #expect(viewModel.title == "Title")
        #expect(viewModel.description == "Description")
        #expect(viewModel.sourceName == "CNN")
        #expect(viewModel.urlWeb == "https://example.com/1")
        #expect(viewModel.urlToImage == "https://example.com/1.jpg")
        #expect(viewModel.image == nil)
    }

    @Test func missingDescriptionBecomesEmptyString() {
        #expect(ViewModel(article: makeArticle(description: nil)).description == "")
    }

    @Test func formatsPublicationDateAsMediumDateShortTimeInUTC() {
        // 2020-11-11T21:04:00Z
        let date = Date(timeIntervalSince1970: 1_605_128_640)
        let expected = DateFormatter()
        expected.timeZone = TimeZone(identifier: "UTC")
        expected.dateStyle = .medium
        expected.timeStyle = .short

        #expect(ViewModel(article: makeArticle()).publishedAt == expected.string(from: date))
    }

    @Test(arguments: ["", "14:52", "2020-11-11"])
    func unparsableDateBecomesEmptyString(publishedAt: String) {
        #expect(ViewModel(article: makeArticle(publishedAt: publishedAt)).publishedAt == "")
    }
}
