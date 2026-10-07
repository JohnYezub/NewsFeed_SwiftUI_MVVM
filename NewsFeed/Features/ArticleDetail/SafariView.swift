//
//  SafariView.swift
//  NewsFeed
//

import SafariServices
import SwiftUI

/// In-app browser for reading the full article.
struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
