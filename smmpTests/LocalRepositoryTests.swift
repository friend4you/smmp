//
//  LocalRepositoryTests.swift
//  smmpTests
//

import CoreData
import Testing
@testable import smmp

struct LocalRepositoryTests {

    private func fetchUser(id: String, persistence: PersistenceController) async throws -> CDUser? {
        let request = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try await persistence.fetch(request).first
    }

    @Test func saveUserCreatesNewRecord() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let user = makeUser()

        try await repository.saveUser(user: user)

        let stored = try await fetchUser(id: user.id, persistence: persistence)
        let id = await user.id
        let displayName = await user.displayName
        let bio = await user.bio
        let photoURL = await user.photoURL
        
        #expect(stored != nil)
        #expect(stored?.id == id)
        #expect(stored?.displayName == displayName)
        #expect(stored?.bio == bio)
        #expect(stored?.photoURL == photoURL)
    }

    @Test func saveUserUpdatesExistingRecord() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let original = makeUser(displayName: "Alice")
        try await repository.saveUser(user: original)

        let updated = makeUser(displayName: "Alicia")
        try await repository.saveUser(user: updated)

        let request = CDUser.fetchRequest()
        let results = try await persistence.fetch(request)
        #expect(results.count == 1)
        #expect(results.first?.displayName == "Alicia")
    }

    @Test func saveUserSetsCachedAtOnInsert() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)

        try await repository.saveUser(user: makeUser())

        let stored = try await fetchUser(id: "user-1", persistence: persistence)
        #expect(stored?.cachedAt != nil)
    }

    @Test func saveUserDoesNotDuplicateOnSecondSave() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let repository = await LocalRepository(persistence: persistence)
        let user = makeUser()

        try await repository.saveUser(user: user)
        try await repository.saveUser(user: user)

        let results = try await persistence.fetch(CDUser.fetchRequest())
        #expect(results.count == 1)
    }
}
