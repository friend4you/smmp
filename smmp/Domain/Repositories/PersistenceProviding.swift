//
//  PersistenceProviding.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

import CoreData

protocol PersistenceProviding {
    func write(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T]
    func fetchOnMain<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T]
    func deleteAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws
}
