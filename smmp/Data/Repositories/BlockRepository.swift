//
//  BlockRepository.swift
//  smmp
//

import FirebaseFirestore
import Foundation

final class BlockRepository: BlockRepositoryProtocol {
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    func block(currentUserId: String, targetUserId: String) async throws {
        guard currentUserId != targetUserId else {
            throw BlockRepositoryError.cannotBlockSelf
        }

        try await blockedDocument(ownerId: currentUserId, blockedId: targetUserId).setData([
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func unblock(currentUserId: String, targetUserId: String) async throws {
        try await blockedDocument(ownerId: currentUserId, blockedId: targetUserId).delete()
    }

    func isBlocked(currentUserId: String, targetUserId: String) async throws -> Bool {
        let snapshot = try await blockedDocument(ownerId: currentUserId, blockedId: targetUserId).getDocument()
        return snapshot.exists
    }

    func blockedIds(for userId: String) async throws -> Set<String> {
        let snapshot = try await blockedCollection(for: userId).getDocuments()
        return Set(snapshot.documents.map(\.documentID))
    }

    func deleteAllBlocks(for userId: String) async throws {
        let snapshot = try await blockedCollection(for: userId).getDocuments()
        guard !snapshot.documents.isEmpty else { return }

        let batch = firestore.batch()
        snapshot.documents.forEach { batch.deleteDocument($0.reference) }
        try await batch.commit()
    }

    private func blockedCollection(for userId: String) -> CollectionReference {
        firestore.collection("users").document(userId).collection("blocked")
    }

    private func blockedDocument(ownerId: String, blockedId: String) -> DocumentReference {
        blockedCollection(for: ownerId).document(blockedId)
    }
}
