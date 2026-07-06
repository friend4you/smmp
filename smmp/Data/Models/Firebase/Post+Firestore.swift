//
//  Post+Firestore.swift
//  smmp
//

import FirebaseFirestore
import Foundation

extension Post {

    init?(documentId: String, data: [String: Any]) {
        guard let authorId = FirestoreFieldParser.optionalString(data["authorId"]) else { return nil }

        self.id = documentId
        self.authorId = authorId
        self.text = FirestoreFieldParser.optionalString(data["text"])
        let rawImageURL = FirestoreFieldParser.optionalString(data["imageURL"])
        self.imageURL = rawImageURL.flatMap { $0.isEmpty ? nil : $0 }
        self.likeCount = FirestoreFieldParser.intValue(data["likeCount"])
        self.commentCount = FirestoreFieldParser.intValue(data["commentCount"])
        self.createdAt = FirestoreFieldParser.date(from: data["createdAt"])
    }

    init?(document: DocumentSnapshot) {
        guard document.exists, let data = document.data() else { return nil }
        self.init(documentId: document.documentID, data: data)
    }
}
