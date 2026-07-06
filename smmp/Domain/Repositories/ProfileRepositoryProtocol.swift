//
//  ProfileRepositoryProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

protocol ProfileRepositoryProtocol {
    func createProfile(uid: String, displayName: String, email: String) async throws -> User
    func fetchUser(id: String) async throws -> User?
}
