//
//  CDUser+CoreDataProperties.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData


public typealias CDUserCoreDataPropertiesSet = NSSet

extension CDUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUser> {
        return NSFetchRequest<CDUser>(entityName: "CDUser")
    }

    @NSManaged public var id: String?
    @NSManaged public var displayName: String?
    @NSManaged public var bio: String?
    @NSManaged public var photoURL: String?
    @NSManaged public var cachedAt: Date?
    @NSManaged public var postId: NSSet?
    @NSManaged public var commentId: NSSet?

}

// MARK: Generated accessors for postId
extension CDUser {

    @objc(addPostIdObject:)
    @NSManaged public func addToPostId(_ value: CDPost)

    @objc(removePostIdObject:)
    @NSManaged public func removeFromPostId(_ value: CDPost)

    @objc(addPostId:)
    @NSManaged public func addToPostId(_ values: NSSet)

    @objc(removePostId:)
    @NSManaged public func removeFromPostId(_ values: NSSet)

}

// MARK: Generated accessors for commentId
extension CDUser {

    @objc(addCommentIdObject:)
    @NSManaged public func addToCommentId(_ value: CDComment)

    @objc(removeCommentIdObject:)
    @NSManaged public func removeFromCommentId(_ value: CDComment)

    @objc(addCommentId:)
    @NSManaged public func addToCommentId(_ values: NSSet)

    @objc(removeCommentId:)
    @NSManaged public func removeFromCommentId(_ values: NSSet)

}

extension CDUser : Identifiable {

}
