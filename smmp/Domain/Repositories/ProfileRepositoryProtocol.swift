//
//  ProfileRepositoryProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

protocol ProfileRepositoryProtocol {
    func fetchUser(id: String) async throws -> User?
}
