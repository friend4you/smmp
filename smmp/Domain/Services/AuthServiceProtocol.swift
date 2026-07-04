//
//  AuthServiceProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(displayName: String, email: String, password: String) async throws -> User
    func signOut() async throws
    func sendPasswordReset(email: String) async throws
}
