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
}
