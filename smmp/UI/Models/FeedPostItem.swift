//
//  FeedPostItem.swift
//  smmp
//

import Foundation

struct FeedPostItem: Identifiable, Hashable {
    var id: String { post.id }

    var post: Post
    var author: User
    var isLikedByCurrentUser: Bool

    static func == (lhs: FeedPostItem, rhs: FeedPostItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static var skeletonPlaceholder: FeedPostItem {
        FeedPostItem(
            post: Post(
                id: "skeleton-post",
                authorId: "skeleton-author",
                text: "Loading post content placeholder",
                likeCount: 12,
                commentCount: 3
            ),
            author: User(id: "skeleton-author", displayName: "Loading Author"),
            isLikedByCurrentUser: false
        )
    }
}
