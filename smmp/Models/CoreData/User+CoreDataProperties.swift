//
//  User+CoreDataProperties.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData


public typealias UserCoreDataPropertiesSet = NSSet

extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var id: String?
    @NSManaged public var displayName: String?
    @NSManaged public var bio: String?
    @NSManaged public var photoURL: String?
    @NSManaged public var cachedAt: Date?
    @NSManaged public var postId: Post?
    @NSManaged public var commentId: Comment?

}

extension User : Identifiable {

}
