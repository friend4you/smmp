//
//  FollowRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Foundation

final class FollowRepository: FollowRepositoryProtocol {
    static let maxFollowingCount = 30

    private let profileRepository: ProfileRepositoryProtocol
    private let followGraph: FollowGraphProtocol

    init(
        profileRepository: ProfileRepositoryProtocol,
        followGraph: FollowGraphProtocol = FirestoreFollowGraphRepository()
    ) {
        self.profileRepository = profileRepository
        self.followGraph = followGraph
    }

    func follow(currentUserId: String, targetUserId: String) async throws {
        guard currentUserId != targetUserId else {
            throw FollowRepositoryError.cannotFollowSelf
        }

        if try await followGraph.isFollowing(followerId: currentUserId, followedId: targetUserId) {
            return
        }

        let user = try await profileRepository.fetchUser(id: currentUserId)
        let followingCount = user?.followingCount ?? 0
        guard followingCount < Self.maxFollowingCount else {
            throw FollowRepositoryError.followingLimitReached
        }

        try await followGraph.followBatch(followerId: currentUserId, followedId: targetUserId)
    }

    func unfollow(currentUserId: String, targetUserId: String) async throws {
        guard try await followGraph.isFollowing(followerId: currentUserId, followedId: targetUserId) else {
            return
        }

        try await followGraph.unfollowBatch(followerId: currentUserId, followedId: targetUserId)
    }

    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool {
        try await followGraph.isFollowing(followerId: currentUserId, followedId: targetUserId)
    }

    func fetchFollowing(for userId: String) async throws -> [Follow] {
        try await followGraph.fetchFollowing(for: userId)
    }

    func followingIds(for userId: String) async throws -> [String] {
        try await followGraph.followingIds(for: userId)
    }
}
