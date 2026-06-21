//
//  CDUser+CoreDataProperties.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//
//

public import Foundation
public import CoreData

extension CDUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUser> {
        return NSFetchRequest<CDUser>(entityName: "CDUser")
    }

    @NSManaged public var id: String?
    @NSManaged public var displayName: String?
    @NSManaged public var email: String?
    @NSManaged public var bio: String?
    @NSManaged public var photoURL: String?
    @NSManaged public var cachedAt: Date?

}

extension CDUser: Identifiable {}
