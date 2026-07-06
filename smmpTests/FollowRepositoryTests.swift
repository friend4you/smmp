//
//  FollowRepositoryTests.swift
//  smmpTests
//

import Foundation
import Testing
@testable import smmp

struct FollowRepositoryTests {

    @Test func followCreatesBatchWhenUnderLimit() async throws {
        let graph = MockFollowGraph()
        let profileRepository = MockFollowProfileRepository(
            users: [makeUser(id: "me", followingCount: 5)]
        )
        let repository = makeRepository(profileRepository: profileRepository, followGraph: graph)

        try await repository.follow(currentUserId: "me", targetUserId: "them")

        #expect(graph.followBatchCalls.count == 1)
        #expect(graph.followBatchCalls[0].0 == "me")
        #expect(graph.followBatchCalls[0].1 == "them")
        #expect(graph.isFollowingCalls.count == 1)
    }

    @Test func followRejectsWhenAtFollowingLimit() async throws {
        let graph = MockFollowGraph()
        let profileRepository = MockFollowProfileRepository(
            users: [makeUser(id: "me", followingCount: 30)]
        )
        let repository = makeRepository(profileRepository: profileRepository, followGraph: graph)

        await #expect(throws: FollowRepositoryError.followingLimitReached) {
            try await repository.follow(currentUserId: "me", targetUserId: "them")
        }

        #expect(graph.followBatchCalls.isEmpty)
    }

    @Test func followRejectsSelfFollow() async throws {
        let graph = MockFollowGraph()
        let repository = makeRepository(followGraph: graph)

        await #expect(throws: FollowRepositoryError.cannotFollowSelf) {
            try await repository.follow(currentUserId: "me", targetUserId: "me")
        }

        #expect(graph.followBatchCalls.isEmpty)
        #expect(graph.isFollowingCalls.isEmpty)
    }

    @Test func followIsIdempotentWhenAlreadyFollowing() async throws {
        let graph = MockFollowGraph(isFollowingByDefault: true)
        let profileRepository = MockFollowProfileRepository(
            users: [makeUser(id: "me", followingCount: 1)]
        )
        let repository = makeRepository(profileRepository: profileRepository, followGraph: graph)

        try await repository.follow(currentUserId: "me", targetUserId: "them")

        #expect(graph.followBatchCalls.isEmpty)
    }

    @Test func followPropagatesBatchErrors() async throws {
        let graph = MockFollowGraph()
        graph.followBatchError = MockFollowError.writeFailed
        let profileRepository = MockFollowProfileRepository(
            users: [makeUser(id: "me", followingCount: 0)]
        )
        let repository = makeRepository(profileRepository: profileRepository, followGraph: graph)

        await #expect(throws: MockFollowError.writeFailed) {
            try await repository.follow(currentUserId: "me", targetUserId: "them")
        }
    }

    @Test func unfollowDeletesBatchWhenFollowing() async throws {
        let graph = MockFollowGraph(isFollowingByDefault: true)
        let repository = makeRepository(followGraph: graph)

        try await repository.unfollow(currentUserId: "me", targetUserId: "them")

        #expect(graph.unfollowBatchCalls.count == 1)
        #expect(graph.unfollowBatchCalls[0].0 == "me")
        #expect(graph.unfollowBatchCalls[0].1 == "them")
    }

    @Test func unfollowIsIdempotentWhenNotFollowing() async throws {
        let graph = MockFollowGraph(isFollowingByDefault: false)
        let repository = makeRepository(followGraph: graph)

        try await repository.unfollow(currentUserId: "me", targetUserId: "them")

        #expect(graph.unfollowBatchCalls.isEmpty)
    }

    @Test func isFollowingDelegatesToFollowGraph() async throws {
        let graph = MockFollowGraph(isFollowingByDefault: true)
        let repository = makeRepository(followGraph: graph)

        let isFollowing = try await repository.isFollowing(currentUserId: "me", targetUserId: "them")

        #expect(isFollowing)
        #expect(graph.isFollowingCalls.count == 1)
        #expect(graph.isFollowingCalls[0].0 == "me")
        #expect(graph.isFollowingCalls[0].1 == "them")
    }

    @Test func followingIdsDelegatesToFollowGraph() async throws {
        let graph = MockFollowGraph(followingIds: ["user-1", "user-2"])
        let repository = makeRepository(followGraph: graph)

        let ids = try await repository.followingIds(for: "me")

        #expect(ids == ["user-1", "user-2"])
        #expect(graph.followingIdsCalls == ["me"])
    }

    @Test func fetchFollowingDelegatesToFollowGraph() async throws {
        let followedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let graph = MockFollowGraph(
            following: [Follow(userId: "user-1", followedAt: followedAt)]
        )
        let repository = makeRepository(followGraph: graph)

        let follows = try await repository.fetchFollowing(for: "me")

        #expect(follows.count == 1)
        #expect(follows.first?.userId == "user-1")
        #expect(graph.fetchFollowingCalls == ["me"])
    }

    // MARK: - Helpers

    private func makeRepository(
        profileRepository: MockFollowProfileRepository = MockFollowProfileRepository(),
        followGraph: MockFollowGraph
    ) -> FollowRepository {
        FollowRepository(
            profileRepository: profileRepository,
            followGraph: followGraph
        )
    }
}

// MARK: - Mocks

private enum MockFollowError: Error {
    case writeFailed
}

private final class MockFollowProfileRepository: ProfileRepositoryProtocol {
    private let usersById: [String: User]

    init(users: [User] = []) {
        self.usersById = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
    }

    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        makeUser(id: uid, displayName: displayName, email: email)
    }

    func fetchUser(id: String) async throws -> User? {
        usersById[id]
    }

    func updateProfile(
        uid: String,
        displayName: String,
        bio: String?,
        profileImageData: Data?,
        removeProfileImage: Bool
    ) async throws -> User {
        makeUser(id: uid, displayName: displayName, bio: bio)
    }

    func searchUsers(prefix: String) async throws -> [User] {
        []
    }
}

private final class MockFollowGraph: FollowGraphProtocol, @unchecked Sendable {
    var isFollowingByDefault = false
    var followingIds: [String] = []
    var following: [Follow] = []
    var followBatchError: Error?

    private(set) var isFollowingCalls: [(String, String)] = []
    private(set) var followingIdsCalls: [String] = []
    private(set) var fetchFollowingCalls: [String] = []
    private(set) var followBatchCalls: [(String, String)] = []
    private(set) var unfollowBatchCalls: [(String, String)] = []

    init(
        isFollowingByDefault: Bool = false,
        followingIds: [String] = [],
        following: [Follow] = []
    ) {
        self.isFollowingByDefault = isFollowingByDefault
        self.followingIds = followingIds
        self.following = following
    }

    func isFollowing(followerId: String, followedId: String) async throws -> Bool {
        isFollowingCalls.append((followerId, followedId))
        return isFollowingByDefault
    }

    func followingIds(for userId: String) async throws -> [String] {
        followingIdsCalls.append(userId)
        return followingIds
    }

    func fetchFollowing(for userId: String) async throws -> [Follow] {
        fetchFollowingCalls.append(userId)
        return following
    }

    func followBatch(followerId: String, followedId: String) async throws {
        followBatchCalls.append((followerId, followedId))
        if let followBatchError {
            throw followBatchError
        }
    }

    func unfollowBatch(followerId: String, followedId: String) async throws {
        unfollowBatchCalls.append((followerId, followedId))
    }
}
