//
//  UserMappingTests.swift
//  smmpTests
//

import CoreData
import Testing
@testable import smmp

struct UserMappingTests {

    @Test func cdUserUpdateMapsAllFields() async throws {
        let persistence = PersistenceController(inMemory: true)
        let user = makeUser()

        try await persistence.write { context in
            let cdUser = CDUser(context: context)
            cdUser.update(user: user)

            #expect(cdUser.id == user.id)
            #expect(cdUser.displayName == user.displayName)
            #expect(cdUser.bio == user.bio)
            #expect(cdUser.photoURL == user.photoURL)
        }
    }

    @Test func userMinimalInitSetsOnlyId() {
        let user = User(id: "x")

        #expect(user.id == "x")
        #expect(user.displayName == nil)
        #expect(user.bio == nil)
        #expect(user.photoURL == nil)
    }
}
