//
//  Post+CoreDataProperties.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData


public typealias PostCoreDataPropertiesSet = NSSet

extension Post {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Post> {
        return NSFetchRequest<Post>(entityName: "Post")
    }

    @NSManaged public var id: String?
    @NSManaged public var text: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var likeCount: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var cachedAt: Date?
    @NSManaged public var authorId: User?
    @NSManaged public var commentId: Comment?

}

extension Post : Identifiable {

}
