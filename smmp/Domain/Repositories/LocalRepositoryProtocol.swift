//
//  LocalRepositoryProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

protocol LocalRepositoryProtocol {
    func saveUser(user: User) async throws
    func fetchUser(id: String) async throws -> User?
    func savePost(post: Post) async throws
    func savePosts(_ posts: [Post]) async throws
    func fetchPosts() async throws -> [Post]
    func saveComment(comment: Comment) async throws
    func fetchComments(postId: String) async throws -> [Comment]
    func deleteComment(id: String) async throws
    func deletePost(id: String) async throws
}
