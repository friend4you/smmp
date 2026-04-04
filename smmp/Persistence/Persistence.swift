//
//  Persistence.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import CoreData

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
        
        container.loadPersistentStores { description, error in
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
