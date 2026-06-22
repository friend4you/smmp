//
//  PostCommentFirestoreMappingTests.swift
//  smmpTests
//

import Foundation
import Testing
@testable import smmp

struct PostCommentFirestoreMappingTests {

    // MARK: - Post

    @Test func postMapsValidDocument() {
        let data: [String: Any] = [
            "authorId": "user-1",
            "text": "Hello feed",
            "imageURL": "https://example.com/p.jpg",
            "likeCount": 3,
            "commentCount": 1
        ]

        let post = Post(documentId: "post-1", data: data)

        #expect(post != nil)
        #expect(post?.id == "post-1")
        #expect(post?.authorId == "user-1")
        #expect(post?.text == "Hello feed")
        #expect(post?.imageURL == "https://example.com/p.jpg")
        #expect(post?.likeCount == 3)
        #expect(post?.commentCount == 1)
        #expect(post?.createdAt == nil)
    }

    @Test func postMapsNullText() {
        let data: [String: Any] = [
            "authorId": "user-1",
            "text": NSNull(),
            "likeCount": 0,
            "commentCount": 0
        ]

        let post = Post(documentId: "post-2", data: data)

        #expect(post != nil)
        #expect(post?.text == nil)
    }

    @Test func postMapsMissingOptionalFields() {
        let data: [String: Any] = [
            "authorId": "user-1",
            "text": "Text only",
            "likeCount": Int64(2),
            "commentCount": NSNumber(value: 4)
        ]

        let post = Post(documentId: "post-3", data: data)

        #expect(post != nil)
        #expect(post?.imageURL == nil)
        #expect(post?.createdAt == nil)
        #expect(post?.likeCount == 2)
        #expect(post?.commentCount == 4)
    }

    @Test func postReturnsNilWhenAuthorIdMissing() {
        let data: [String: Any] = [
            "text": "Orphan",
            "likeCount": 0,
            "commentCount": 0
        ]

        #expect(Post(documentId: "post-4", data: data) == nil)
    }

    // MARK: - Comment

    @Test func commentMapsValidDocument() {
        let data: [String: Any] = [
            "authorId": "user-2",
            "text": "Nice post"
        ]

        let comment = Comment(documentId: "comment-1", postId: "post-1", data: data)

        #expect(comment != nil)
        #expect(comment?.id == "comment-1")
        #expect(comment?.postId == "post-1")
        #expect(comment?.authorId == "user-2")
        #expect(comment?.text == "Nice post")
        #expect(comment?.createdAt == nil)
    }

    @Test func commentMapsNullText() {
        let data: [String: Any] = [
            "authorId": "user-2",
            "text": NSNull()
        ]

        let comment = Comment(documentId: "comment-2", postId: "post-1", data: data)

        #expect(comment != nil)
        #expect(comment?.text == nil)
    }

    @Test func commentReturnsNilWhenAuthorIdMissing() {
        let data: [String: Any] = [
            "text": "No author"
        ]

        #expect(Comment(documentId: "comment-3", postId: "post-1", data: data) == nil)
    }

    // MARK: - FeedPostItem

    @Test func feedPostItemExposesPostId() {
        let post = Post(
            id: "post-99",
            authorId: "user-1",
            text: "Hi",
            imageURL: nil,
            likeCount: 0,
            commentCount: 0,
            createdAt: nil
        )
        let item = FeedPostItem(post: post, author: makeUser(), isLikedByCurrentUser: false)

        #expect(item.id == "post-99")
        #expect(item.isLikedByCurrentUser == false)
    }
}
