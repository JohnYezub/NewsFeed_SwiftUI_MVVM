//
//  NewsFeedWatchApp.swift
//  NewsFeedWatch
//

import SwiftUI

@main
struct NewsFeedWatchApp: App {

    @State private var viewModel = NewsListViewModel()

    var body: some Scene {
        WindowGroup {
            WatchNewsListView(viewModel: viewModel)
        }
    }
}
