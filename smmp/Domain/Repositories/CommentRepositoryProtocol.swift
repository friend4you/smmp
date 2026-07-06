//
//  CommentRepositoryProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

protocol CommentRepositoryProtocol: AnyObject {
    func fetchComments(postId: String) async throws -> [Comment]
    func addComment(postId: String, text: String, authorId: String) async throws
    func deleteComment(postId: String, commentId: String, authorId: String) async throws
}
