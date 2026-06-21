//
//  AuthRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func register(displayName: String, email: String, password: String) async throws -> User
    func signOut() async throws
    func sendPasswordReset(email: String) async throws
}

class AuthRepository: AuthRepositoryProtocol {
    private let authService: AuthServiceProtocol

    init(authService: AuthService) {
        self.authService = authService
    }

    func login(email: String, password: String) async throws -> User {
        try await authService.login(email: email, password: password)
    }

    func register(displayName: String, email: String, password: String) async throws -> User {
        try await authService.register(
            displayName: displayName,
            email: email,
            password: password
        )
    }

    func signOut() async throws {
        try await authService.signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await authService.sendPasswordReset(email: email)
    }
}
