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
    var bio: String?
    var photoURL: String?
    
    init(firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL?.absoluteString
        self.bio = firebaseUser.email
    }
    
    init(id: String) {
        self.id = id
    }
}
