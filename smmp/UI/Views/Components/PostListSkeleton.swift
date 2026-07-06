//
//  PostListSkeleton.swift
//  smmp
//

import SwiftUI

struct PostListSkeleton: View {
    var count: Int = 3

    var body: some View {
        ForEach(0..<count, id: \.self) { _ in
            PostCardView(item: .skeletonPlaceholder, onLikeTapped: {})
                .redacted(reason: .placeholder)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    PostListSkeleton()
        .padding()
}
