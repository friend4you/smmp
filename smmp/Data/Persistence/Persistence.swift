//
//  Persistence.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

@preconcurrency import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let viewContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    
    private let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "smmp")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData failed to load: \(error.localizedDescription)")
            }
        }
        
        viewContext = container.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.shouldDeleteInaccessibleFaults = true
        
        backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.undoManager = nil
    }
}

extension PersistenceController: PersistenceProviding {
    func write(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        try await backgroundContext.perform {
            try block(self.backgroundContext)
            guard self.backgroundContext.hasChanges else { return }
            try self.backgroundContext.save()
        }
    }
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        try await backgroundContext.perform {
            try self.backgroundContext.fetch(request)
        }
    }
    
    func fetchOnMain<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        try viewContext.fetch(request)
    }
    
    func deleteAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws {
        try await write { context in
            let objects = try context.fetch(request)
            objects.forEach(context.delete)
        }
    }
    
}
