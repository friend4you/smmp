//
//  PostRepositoryProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

import Combine

protocol PostRepositoryProtocol: AnyObject {
    var postsPublisher: AnyPublisher<[Post], Never> { get }
    var likedPostIdsPublisher: AnyPublisher<Set<String>, Never> { get }

    func observeFeed(currentUserId: String)
    func removeAllListeners()
    func refreshFeed(currentUserId: String) async throws
    @discardableResult
    func loadMorePosts(currentUserId: String) async throws -> Bool
    func newPostId() -> String
    func createPost(text: String, authorId: String, postId: String?, imageURL: String?) async throws
    func deletePost(id: String, authorId: String) async throws
    func likePost(id: String, userId: String) async throws
    func unlikePost(id: String, userId: String) async throws
}
