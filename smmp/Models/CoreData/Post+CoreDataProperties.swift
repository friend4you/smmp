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

    @NSManaged public var id: NSObject?
    @NSManaged public var text: NSObject?
    @NSManaged public var imageURL: NSObject?
    @NSManaged public var likeCount: NSObject?
    @NSManaged public var createdAt: NSObject?
    @NSManaged public var cachedAt: NSObject?
    @NSManaged public var authorId: User?

}

extension Post : Identifiable {

}
