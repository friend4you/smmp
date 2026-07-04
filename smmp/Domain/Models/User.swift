//
//  User.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import FirebaseAuth

struct User {

    var id: String
    var displayName: String?
    var email: String?
    var bio: String?
    var photoURL: String?

    init(id: String) {
        self.id = id
    }
}
