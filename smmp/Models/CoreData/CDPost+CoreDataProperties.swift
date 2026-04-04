//
//  CDPost+CoreDataProperties.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData


public typealias CDPostCoreDataPropertiesSet = NSSet

extension CDPost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDPost> {
        return NSFetchRequest<CDPost>(entityName: "CDPost")
    }

    @NSManaged public var id: String?
    @NSManaged public var text: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var likeCount: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var cachedAt: Date?
    @NSManaged public var authorId: CDUser?
    @NSManaged public var commentId: NSSet?

}

// MARK: Generated accessors for commentId
extension CDPost {

    @objc(addCommentIdObject:)
    @NSManaged public func addToCommentId(_ value: CDComment)

    @objc(removeCommentIdObject:)
    @NSManaged public func removeFromCommentId(_ value: CDComment)

    @objc(addCommentId:)
    @NSManaged public func addToCommentId(_ values: NSSet)

    @objc(removeCommentId:)
    @NSManaged public func removeFromCommentId(_ values: NSSet)

}

extension CDPost : Identifiable {

}
