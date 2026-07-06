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
        displayNameLower = user.displayNameLower ?? User.displayNameLower(from: user.displayName)
        email = user.email
        bio = user.bio
        followerCount = Int64(user.followerCount)
        followingCount = Int64(user.followingCount)
    }

    func toUser() -> User? {
        guard let id else { return nil }

        var user = User(id: id)
        user.displayName = displayName
        user.displayNameLower = displayNameLower
        user.email = email
        user.bio = bio
        user.photoURL = photoURL
        user.followerCount = Int(followerCount)
        user.followingCount = Int(followingCount)
        return user
    }
}
