//
//  CDComment+CoreDataProperties.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData


public typealias CDCommentCoreDataPropertiesSet = NSSet

extension CDComment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDComment> {
        return NSFetchRequest<CDComment>(entityName: "CDComment")
    }

    @NSManaged public var id: String?
    @NSManaged public var text: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var authorId: CDUser?
    @NSManaged public var postId: CDPost?

}

extension CDComment : Identifiable {

}
