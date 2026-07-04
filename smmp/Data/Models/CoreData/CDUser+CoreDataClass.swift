//
//  CDUser+CoreDataClass.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData

public typealias CDUserCoreDataClassSet = NSSet

@objc(CDUser)
public class CDUser: NSManagedObject {

    func update(user: User) {
        id = user.id
        photoURL = user.photoURL
        displayName = user.displayName
        email = user.email
        bio = user.bio
    }

    func toUser() -> User? {
        guard let id else { return nil }

        var user = User(id: id)
        user.displayName = displayName
        user.email = email
        user.bio = bio
        user.photoURL = photoURL
        return user
    }
}
