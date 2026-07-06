//
//  FirestoreUserDocumentRepository.swift
//  smmp
//

import FirebaseFirestore
import Foundation

struct FirestoreUserDocumentRepository: UserDocumentProtocol {
    func fetchUserDocument(id: String) async throws -> User? {
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(id)
            .getDocument()
        return User(document: snapshot)
    }

    func createUserDocument(id: String, data: [String: Any]) async throws {
        try await Firestore.firestore()
            .collection("users")
            .document(id)
            .setData(data)
    }

    func updateUserDocument(id: String, data: [String: Any]) async throws {
        try await Firestore.firestore()
            .collection("users")
            .document(id)
            .updateData(data)
    }

    func searchUsers(prefix: String, limit: Int) async throws -> [User] {
        let end = prefix + "\u{f8ff}"
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .whereField("displayNameLower", isGreaterThanOrEqualTo: prefix)
            .whereField("displayNameLower", isLessThan: end)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { User(document: $0) }
    }
}
