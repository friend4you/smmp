//
//  ProfileRepositoryProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

import Foundation

protocol ProfileRepositoryProtocol {
    func createProfile(uid: String, displayName: String, email: String) async throws -> User
    func fetchUser(id: String) async throws -> User?
    func updateProfile(
        uid: String,
        displayName: String,
        bio: String?,
        profileImageData: Data?,
        removeProfileImage: Bool
    ) async throws -> User
    func searchUsers(prefix: String) async throws -> [User]
}
