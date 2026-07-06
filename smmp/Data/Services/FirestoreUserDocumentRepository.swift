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
}
