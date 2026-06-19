//
//  ContentView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem { Label(.tabHome, systemImage: "house") }
                .tag(Tab.feed)
            SearchView()
                .tabItem { Label(.tabSearch, systemImage: "magnifyingglass") }
                .tag(Tab.search)
            NewPostView()
                .tabItem { Label(.tabPost, systemImage: "plus.square") }
                .tag(Tab.newPost)
            ProfileView()
                .tabItem { Label(.tabProfile, systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)
        }
    }
}

#Preview {
    ContentView()
}
