//
//  TestHelpers.swift
//  smmpTests
//

@testable import smmp

func makeUser(
    id: String = "user-1",
    displayName: String? = "Alice",
    email: String? = "alice@example.com",
    bio: String? = "Hello",
    photoURL: String? = "https://example.com/a.jpg"
) -> User {
    var user = User(id: id)
    user.displayName = displayName
    user.email = email
    user.bio = bio
    user.photoURL = photoURL
    return user
}
