//
//  CommentRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import FirebaseFirestore
import Foundation

protocol CommentRepositoryProtocol: AnyObject {
    func fetchComments(postId: String) async throws -> [Comment]
    func addComment(postId: String, text: String, authorId: String) async throws
    func deleteComment(postId: String, commentId: String, authorId: String) async throws
}

final class CommentRepository: CommentRepositoryProtocol {
    private let networkMonitor: NetworkConnectivityProviding
    private let localRepository: LocalRepositoryProtocol
    private let persistence: PersistenceController
    private let mediaService: MediaServiceProtocol
    private let firestore: Firestore

    init(
        networkMonitor: NetworkConnectivityProviding,
        localRepository: LocalRepositoryProtocol,
        persistence: PersistenceController,
        mediaService: MediaServiceProtocol,
        firestore: Firestore = Firestore.firestore()
    ) {
        self.networkMonitor = networkMonitor
        self.localRepository = localRepository
        self.persistence = persistence
        self.mediaService = mediaService
        self.firestore = firestore
    }

    func fetchComments(postId: String) async throws -> [Comment] {
        guard networkMonitor.isConnected else {
            return try await localRepository.fetchComments(postId: postId)
        }

        let snapshot = try await commentsQuery(postId: postId).getDocuments()
        let comments = snapshot.documents.compactMap { Comment(document: $0, postId: postId) }

        for comment in comments {
            try await localRepository.saveComment(comment: comment)
        }

        return comments
    }

    func addComment(postId: String, text: String, authorId: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CommentRepositoryError.emptyText }

        let postRef = firestore.collection("posts").document(postId)
        let commentRef = postRef.collection("comments").document()

        let batch = firestore.batch()
        batch.setData(
            [
                "authorId": authorId,
                "text": trimmed,
                "createdAt": FieldValue.serverTimestamp()
            ],
            forDocument: commentRef
        )
        batch.updateData(["commentCount": FieldValue.increment(Int64(1))], forDocument: postRef)
        try await batch.commit()
    }

    func deleteComment(postId: String, commentId: String, authorId: String) async throws {
        let commentRef = firestore.collection("posts")
            .document(postId)
            .collection("comments")
            .document(commentId)

        let snapshot = try await commentRef.getDocument()
        guard snapshot.exists else { throw CommentRepositoryError.commentNotFound }
        guard snapshot.data()?["authorId"] as? String == authorId else {
            throw CommentRepositoryError.unauthorizedDelete
        }

        let postRef = firestore.collection("posts").document(postId)
        let batch = firestore.batch()
        batch.deleteDocument(commentRef)
        batch.updateData(["commentCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
        try await batch.commit()

        try await localRepository.deleteComment(id: commentId)
    }

    // MARK: - Private

    private func commentsQuery(postId: String) -> Query {
        firestore.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
    }
}
