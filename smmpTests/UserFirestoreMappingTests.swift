//
//  UserFirestoreMappingTests.swift
//  smmpTests
//

import Foundation
import Testing
@testable import smmp

struct UserFirestoreMappingTests {

    @Test func userMapsValidDocument() {
        let data: [String: Any] = [
            "displayName": "Alice",
            "displayNameLower": "alice",
            "email": "alice@example.com",
            "bio": "Hello",
            "photoURL": "https://example.com/a.jpg",
            "followerCount": 5,
            "followingCount": 12
        ]

        let user = User(documentId: "user-1", data: data)

        #expect(user != nil)
        #expect(user?.id == "user-1")
        #expect(user?.displayName == "Alice")
        #expect(user?.displayNameLower == "alice")
        #expect(user?.email == "alice@example.com")
        #expect(user?.bio == "Hello")
        #expect(user?.photoURL == "https://example.com/a.jpg")
        #expect(user?.followerCount == 5)
        #expect(user?.followingCount == 12)
    }

    @Test func userMapsMissingCountsAsZero() {
        let data: [String: Any] = [
            "displayName": "Bob",
            "email": "bob@example.com"
        ]

        let user = User(documentId: "user-2", data: data)

        #expect(user != nil)
        #expect(user?.followerCount == 0)
        #expect(user?.followingCount == 0)
        #expect(user?.displayNameLower == nil)
    }

    @Test func userMapsNumericCountTypes() {
        let data: [String: Any] = [
            "displayName": "Carol",
            "followerCount": Int64(3),
            "followingCount": NSNumber(value: 7)
        ]

        let user = User(documentId: "user-3", data: data)

        #expect(user?.followerCount == 3)
        #expect(user?.followingCount == 7)
    }

    @Test func userMapsNullOptionalStrings() {
        let data: [String: Any] = [
            "displayName": "Dana",
            "bio": NSNull(),
            "photoURL": NSNull(),
            "displayNameLower": NSNull(),
            "followerCount": 0,
            "followingCount": 0
        ]

        let user = User(documentId: "user-4", data: data)

        #expect(user?.bio == nil)
        #expect(user?.photoURL == nil)
        #expect(user?.displayNameLower == nil)
    }

    @Test func firestoreWriteDataIncludesProfileFields() {
        let user = makeUser(
            displayName: "Alice",
            followerCount: 2,
            followingCount: 4,
            displayNameLower: "alice"
        )

        let data = user.firestoreWriteData()

        #expect(data["displayName"] as? String == "Alice")
        #expect(data["displayNameLower"] as? String == "alice")
        #expect(data["bio"] as? String == "Hello")
        #expect(data["photoURL"] as? String == "https://example.com/a.jpg")
        #expect(data["followerCount"] as? Int == 2)
        #expect(data["followingCount"] as? Int == 4)
        #expect(data["email"] == nil)
    }

    @Test func firestoreWriteDataDerivesDisplayNameLowerWhenMissing() {
        var user = makeUser(displayName: "Eve")
        user.displayNameLower = nil

        let data = user.firestoreWriteData()

        #expect(data["displayNameLower"] as? String == "eve")
    }

    @Test func firestoreWriteDataCanIncludeEmail() {
        let user = makeUser(email: "alice@example.com")

        let data = user.firestoreWriteData(includeEmail: true)

        #expect(data["email"] as? String == "alice@example.com")
    }

    @Test func displayNameLowerHelperLowercases() {
        #expect(User.displayNameLower(from: "Alice") == "alice")
        #expect(User.displayNameLower(from: nil) == nil)
    }
}
