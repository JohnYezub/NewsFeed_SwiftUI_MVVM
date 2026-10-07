//
//  NewsFeedApp.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import SwiftUI

@main
struct NewsFeedApp: App {

    @State private var viewModel = NewsListViewModel()

    init() {
        // AsyncImage loads through URLSession.shared; the default cache is too small to keep thumbnails.
        URLCache.shared = URLCache(memoryCapacity: 50_000_000, diskCapacity: 200_000_000)
    }

    var body: some Scene {
        WindowGroup {
            NewsListView(viewModel: viewModel)
        }
    }
}
