//
//  Comment+Firestore.swift
//  smmp
//

import FirebaseFirestore
import Foundation

extension Comment {

    init?(documentId: String, postId: String, data: [String: Any]) {
        guard let authorId = data["authorId"] as? String else { return nil }

        self.id = documentId
        self.postId = postId
        self.authorId = authorId
        self.text = FirestoreFieldParser.optionalString(data["text"])
        self.createdAt = FirestoreFieldParser.date(from: data["createdAt"])
    }

    init?(document: DocumentSnapshot, postId: String) {
        guard document.exists, let data = document.data() else { return nil }
        self.init(documentId: document.documentID, postId: postId, data: data)
    }
}
