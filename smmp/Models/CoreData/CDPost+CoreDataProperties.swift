//
//  CDPost+CoreDataProperties.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData

extension CDPost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDPost> {
        return NSFetchRequest<CDPost>(entityName: "CDPost")
    }

    @NSManaged public var id: String?
    @NSManaged public var authorId: String?
    @NSManaged public var text: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var likeCount: Int64
    @NSManaged public var commentCount: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var cachedAt: Date?

}

extension CDPost: Identifiable {}
