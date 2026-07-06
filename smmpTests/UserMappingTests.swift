//
//  UserMappingTests.swift
//  smmpTests
//

import CoreData
import Testing
@testable import smmp

struct UserMappingTests {

    @Test func cdUserUpdateMapsAllFields() async throws {
        let persistence = await PersistenceController(inMemory: true)
        let user = makeUser()

        try await persistence.write { context in
            let cdUser = CDUser(context: context)
            cdUser.update(user: user)

            #expect(cdUser.id == user.id)
            #expect(cdUser.displayName == user.displayName)
            #expect(cdUser.displayNameLower == user.displayNameLower)
            #expect(cdUser.email == user.email)
            #expect(cdUser.bio == user.bio)
            #expect(cdUser.photoURL == user.photoURL)
            #expect(cdUser.followerCount == Int64(user.followerCount))
            #expect(cdUser.followingCount == Int64(user.followingCount))
        }
    }

    @Test func userMinimalInitSetsOnlyId() {
        let user = User(id: "x")

        #expect(user.id == "x")
        #expect(user.displayName == nil)
        #expect(user.email == nil)
        #expect(user.bio == nil)
        #expect(user.photoURL == nil)
        #expect(user.followerCount == 0)
        #expect(user.followingCount == 0)
        #expect(user.displayNameLower == nil)
    }
}
