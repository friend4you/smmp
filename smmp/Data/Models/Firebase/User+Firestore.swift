//
//  User+Firestore.swift
//  smmp
//

import FirebaseFirestore
import FirebaseAuth
import Foundation

extension User {

    init?(document: DocumentSnapshot) {
        guard document.exists, let data = document.data() else { return nil }
        self.init(documentId: document.documentID, data: data)
    }

    init?(documentId: String, data: [String: Any]) {
        self.id = documentId
        self.displayName = FirestoreFieldParser.optionalString(data["displayName"])
        self.displayNameLower = FirestoreFieldParser.optionalString(data["displayNameLower"])
        self.email = FirestoreFieldParser.optionalString(data["email"])
        self.bio = FirestoreFieldParser.optionalString(data["bio"])
        self.photoURL = FirestoreFieldParser.optionalString(data["photoURL"])
        self.followerCount = FirestoreFieldParser.intValue(data["followerCount"])
        self.followingCount = FirestoreFieldParser.intValue(data["followingCount"])
    }

    init(firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.displayName = firebaseUser.displayName
        self.email = firebaseUser.email
        self.photoURL = firebaseUser.photoURL?.absoluteString
        self.bio = nil
        self.followerCount = 0
        self.followingCount = 0
        self.displayNameLower = User.displayNameLower(from: firebaseUser.displayName)
    }

    /// Fields written to `users/{uid}` on profile create or update.
    func firestoreWriteData(includeEmail: Bool = false) -> [String: Any] {
        var data: [String: Any] = [
            "followerCount": followerCount,
            "followingCount": followingCount
        ]

        if let displayName {
            data["displayName"] = displayName
        }
        if let lower = displayNameLower ?? User.displayNameLower(from: displayName) {
            data["displayNameLower"] = lower
        }
        if let bio {
            data["bio"] = bio
        }
        if let photoURL {
            data["photoURL"] = photoURL
        } else {
            data["photoURL"] = ""
        }
        if includeEmail, let email {
            data["email"] = email
        }

        return data
    }
}
