//
//  MockSessionService.swift
//  smmpTests
//

@testable import smmp

@MainActor
final class MockSessionService: SessionServiceProtocol {
    var currentUser: User?
    var sessionState: AuthSession = .idle

    var isAuthenticated: Bool { currentUser != nil }

    init(currentUser: User? = nil, sessionState: AuthSession = .idle) {
        self.currentUser = currentUser
        self.sessionState = sessionState
    }
}
