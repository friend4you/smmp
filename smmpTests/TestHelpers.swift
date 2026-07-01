//
//  TestHelpers.swift
//  smmpTests
//

import Foundation
@testable import smmp

func makeUser(
    id: String = "user-1",
    displayName: String? = "Alice",
    email: String? = "alice@example.com",
    bio: String? = "Hello",
    photoURL: String? = "https://example.com/a.jpg"
) -> User {
    var user = User(id: id)
    user.displayName = displayName
    user.email = email
    user.bio = bio
    user.photoURL = photoURL
    return user
}

func makePost(
    id: String = "post-1",
    authorId: String = "user-1",
    text: String? = "Hello feed",
    imageURL: String? = nil,
    likeCount: Int = 0,
    commentCount: Int = 0,
    createdAt: Date? = Date(timeIntervalSince1970: 1_700_000_000)
) -> Post {
    Post(
        id: id,
        authorId: authorId,
        text: text,
        imageURL: imageURL,
        likeCount: likeCount,
        commentCount: commentCount,
        createdAt: createdAt
    )
}

func makeComment(
    id: String = "comment-1",
    postId: String = "post-1",
    authorId: String = "user-2",
    text: String? = "Nice post",
    createdAt: Date? = Date(timeIntervalSince1970: 1_700_000_100)
) -> Comment {
    Comment(
        id: id,
        postId: postId,
        authorId: authorId,
        text: text,
        createdAt: createdAt
    )
}

func makeFeedPostItem(
    post: Post = makePost(),
    author: User = makeUser(),
    isLikedByCurrentUser: Bool = false
) -> FeedPostItem {
    FeedPostItem(
        post: post,
        author: author,
        isLikedByCurrentUser: isLikedByCurrentUser
    )
}
