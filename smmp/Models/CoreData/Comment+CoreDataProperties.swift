//
//  Comment+CoreDataProperties.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData


public typealias CommentCoreDataPropertiesSet = NSSet

extension Comment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comment> {
        return NSFetchRequest<Comment>(entityName: "Comment")
    }

    @NSManaged public var id: NSObject?
    @NSManaged public var text: NSObject?
    @NSManaged public var createdAt: NSObject?
    @NSManaged public var authorId: User?
    @NSManaged public var postId: Post?

}

extension Comment : Identifiable {

}
