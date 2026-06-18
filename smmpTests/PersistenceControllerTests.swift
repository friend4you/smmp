//
//  PersistenceControllerTests.swift
//  smmpTests
//

import CoreData
import Testing
@testable import smmp

struct PersistenceControllerTests {

    @Test func writePersistsAndFetchReturnsObject() async throws {
        let persistence = PersistenceController(inMemory: true)

        try await persistence.write { context in
            let user = CDUser(context: context)
            user.id = "u1"
        }

        let results = try await persistence.fetch(CDUser.fetchRequest())
        #expect(results.count == 1)
        #expect(results.first?.id == "u1")
    }

    @Test func fetchOnMainSeesBackgroundWrites() async throws {
        let persistence = PersistenceController(inMemory: true)

        try await persistence.write { context in
            let user = CDUser(context: context)
            user.id = "u1"
        }

        let results = try persistence.fetchOnMain(CDUser.fetchRequest())
        #expect(results.count == 1)
        #expect(results.first?.id == "u1")
    }

    @Test func deleteAllRemovesMatchingEntities() async throws {
        let persistence = PersistenceController(inMemory: true)

        try await persistence.write { context in
            let first = CDUser(context: context)
            first.id = "u1"
            let second = CDUser(context: context)
            second.id = "u2"
        }

        try await persistence.deleteAll(CDUser.fetchRequest())

        let results = try await persistence.fetch(CDUser.fetchRequest())
        #expect(results.isEmpty)
    }
}
