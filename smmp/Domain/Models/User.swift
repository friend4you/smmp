//
//  User.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

struct User: Hashable {
    var id: String
    var displayName: String?
    var email: String?
    var bio: String?
    var photoURL: String?
    var followerCount: Int = 0
    var followingCount: Int = 0
    var displayNameLower: String?

    static func displayNameLower(from displayName: String?) -> String? {
        displayName?.lowercased()
    }
}
