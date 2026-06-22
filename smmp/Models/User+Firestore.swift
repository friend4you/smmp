//
//  User+Firestore.swift
//  smmp
//

import FirebaseFirestore
import Foundation

extension User {

    init?(document: DocumentSnapshot) {
        guard document.exists, let data = document.data() else { return nil }
        self.init(documentId: document.documentID, data: data)
    }

    init?(documentId: String, data: [String: Any]) {
        self.id = documentId
        self.displayName = FirestoreFieldParser.optionalString(data["displayName"])
        self.email = FirestoreFieldParser.optionalString(data["email"])
        self.bio = FirestoreFieldParser.optionalString(data["bio"])
        self.photoURL = FirestoreFieldParser.optionalString(data["photoURL"])
    }
}
