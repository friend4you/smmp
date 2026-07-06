//
//  FirestoreFollowGraphRepository.swift
//  smmp
//

import FirebaseFirestore
import Foundation

struct FirestoreFollowGraphRepository: FollowGraphProtocol {
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    func isFollowing(followerId: String, followedId: String) async throws -> Bool {
        let snapshot = try await followingDocument(followerId: followerId, followedId: followedId).getDocument()
        return snapshot.exists
    }

    func followingIds(for userId: String) async throws -> [String] {
        let snapshot = try await followingCollection(for: userId).getDocuments()
        return snapshot.documents.map(\.documentID)
    }

    func fetchFollowing(for userId: String) async throws -> [Follow] {
        let snapshot = try await followingCollection(for: userId)
            .order(by: "followedAt", descending: true)
            .getDocuments()
        return snapshot.documents.map { document in
            let followedAt = (document.data()["followedAt"] as? Timestamp)?.dateValue()
            return Follow(userId: document.documentID, followedAt: followedAt)
        }
    }

    func followBatch(followerId: String, followedId: String) async throws {
        let batch = firestore.batch()
        let followingRef = followingDocument(followerId: followerId, followedId: followedId)
        let followerRef = firestore.collection("users").document(followerId)
        let followedRef = firestore.collection("users").document(followedId)

        batch.setData(["followedAt": FieldValue.serverTimestamp()], forDocument: followingRef)
        batch.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: followerRef)
        batch.updateData(["followerCount": FieldValue.increment(Int64(1))], forDocument: followedRef)
        try await batch.commit()
    }

    func unfollowBatch(followerId: String, followedId: String) async throws {
        let batch = firestore.batch()
        let followingRef = followingDocument(followerId: followerId, followedId: followedId)
        let followerRef = firestore.collection("users").document(followerId)
        let followedRef = firestore.collection("users").document(followedId)

        batch.deleteDocument(followingRef)
        batch.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: followerRef)
        batch.updateData(["followerCount": FieldValue.increment(Int64(-1))], forDocument: followedRef)
        try await batch.commit()
    }

    private func followingCollection(for userId: String) -> CollectionReference {
        firestore.collection("users").document(userId).collection("following")
    }

    private func followingDocument(followerId: String, followedId: String) -> DocumentReference {
        followingCollection(for: followerId).document(followedId)
    }
}
