//
//  FollowGraphProtocol.swift
//  smmp
//

protocol FollowGraphProtocol: Sendable {
    func isFollowing(followerId: String, followedId: String) async throws -> Bool
    func followingIds(for userId: String) async throws -> [String]
    func fetchFollowing(for userId: String) async throws -> [Follow]
    func followBatch(followerId: String, followedId: String) async throws
    func unfollowBatch(followerId: String, followedId: String) async throws
}
