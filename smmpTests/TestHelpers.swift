//
//  TestHelpers.swift
//  smmpTests
//

@testable import smmp

func makeUser(
    id: String = "user-1",
    displayName: String? = "Alice",
    bio: String? = "Hello",
    photoURL: String? = "https://example.com/a.jpg"
) -> User {
    var user = User(id: id)
    user.displayName = displayName
    user.bio = bio
    user.photoURL = photoURL
    return user
}
