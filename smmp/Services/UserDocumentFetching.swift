//
//  UserDocumentFetching.swift
//  smmp
//

import FirebaseFirestore
import Foundation

protocol UserDocumentFetching: Sendable {
    func fetchUserDocument(id: String) async throws -> User?
}

struct FirestoreUserDocumentFetcher: UserDocumentFetching {
    func fetchUserDocument(id: String) async throws -> User? {
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(id)
            .getDocument()
        return User(document: snapshot)
    }
}
