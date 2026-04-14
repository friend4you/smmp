//
//  LocalRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/6/26.
//

import Foundation
import CoreData

protocol LocalRepositoryProtocol {
    func saveUser(user: User) async throws
}

class LocalRepository: LocalRepositoryProtocol {
    private let persistence: PersistenceController
    
    init(persistence: PersistenceController) {
        self.persistence = persistence
    }
    
    func saveUser(user: User) async throws {
        let request = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", user.id)
        guard let cdUser = try? await persistence.fetch(request).first else {
            try await persistence.write { context in
                let newUser = CDUser(context: context)
                newUser.update(user: user)
                newUser.cachedAt = Date.now
            }
            
            return
        }
        
        try await persistence.write { context in
            cdUser.update(user: user)
        }
    }
}
