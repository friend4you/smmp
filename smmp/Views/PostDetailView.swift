//
//  PostDetailView.swift
//  smmp
//

import SwiftUI

struct PostDetailView: View {
    let item: FeedPostItem

    var body: some View {
        ScrollView {
            PostCardView(item: item, onLikeTapped: {})
                .padding()
        }
        .navigationTitle(Text(.feedTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}
