//
//  SessionServiceTests.swift
//  smmpTests
//

import Testing
@testable import smmp

@MainActor
struct SessionServiceTests {

    @Test func startsResolvingSession() {
        let service = SessionService()
        #expect(service.isResolvingSession)
        #expect(service.currentUser == nil)
        #expect(!service.isAuthenticated)
    }
}
