//
//  Post+Firestore.swift
//  smmp
//

import FirebaseFirestore
import Foundation

extension Post {

    init?(documentId: String, data: [String: Any]) {
        guard let authorId = data["authorId"] as? String else { return nil }

        self.id = documentId
        self.authorId = authorId
        self.text = FirestoreFieldParser.optionalString(data["text"])
        self.imageURL = FirestoreFieldParser.optionalString(data["imageURL"])
        self.likeCount = FirestoreFieldParser.intValue(data["likeCount"])
        self.commentCount = FirestoreFieldParser.intValue(data["commentCount"])
        self.createdAt = FirestoreFieldParser.date(from: data["createdAt"])
    }

    init?(document: DocumentSnapshot) {
        guard document.exists, let data = document.data() else { return nil }
        self.init(documentId: document.documentID, data: data)
    }
}
