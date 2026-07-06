//
//  AuthRepositoryProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func register(displayName: String, email: String, password: String) async throws -> User
    func signOut() async throws
    func sendPasswordReset(email: String) async throws
}
