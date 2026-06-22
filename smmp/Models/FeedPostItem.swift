//
//  FeedPostItem.swift
//  smmp
//

import Foundation

struct FeedPostItem: Identifiable {
    var id: String { post.id }

    let post: Post
    let author: User
    var isLikedByCurrentUser: Bool
}
