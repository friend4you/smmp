//
//  FollowRepositoryProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

import Foundation

protocol FollowRepositoryProtocol {
    func follow(currentUserId: String, targetUserId: String) async throws
    func unfollow(currentUserId: String, targetUserId: String) async throws
    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool
    func fetchFollowing(for userId: String) async throws -> [Follow]
    func followingIds(for userId: String) async throws -> [String]
}
