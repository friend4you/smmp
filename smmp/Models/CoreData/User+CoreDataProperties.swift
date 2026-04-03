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

    @NSManaged public var id: NSObject?
    @NSManaged public var displayName: NSObject?
    @NSManaged public var bio: NSObject?
    @NSManaged public var photoURL: NSObject?
    @NSManaged public var cachedAt: NSObject?

}

extension User : Identifiable {

}
