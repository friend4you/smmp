//
//  AppCoordinatorTests.swift
//  smmpTests
//

import Testing
@testable import smmp

@MainActor
struct AppCoordinatorTests {

    @Test func createsAuthCoordinatorWhenUnauthenticated() {
        let deps = AppDependencies()
        let sessionService = SessionService()
        let coordinator = AppCoordinator(deps: deps, sessionService: sessionService)

        coordinator.handleAuthenticationChange(isAuthenticated: false)

        #expect(coordinator.authCoordinator != nil)
        #expect(coordinator.mainCoordinator == nil)
        #expect(coordinator.authCoordinatorGeneration == 1)
    }

    @Test func createsMainCoordinatorWhenAuthenticated() {
        let deps = AppDependencies()
        let sessionService = SessionService()
        let coordinator = AppCoordinator(deps: deps, sessionService: sessionService)

        coordinator.handleAuthenticationChange(isAuthenticated: true)

        #expect(coordinator.mainCoordinator != nil)
        #expect(coordinator.authCoordinator == nil)
        #expect(coordinator.mainCoordinatorGeneration == 1)
    }

    @Test func recreatesCoordinatorsOnAuthTransition() {
        let deps = AppDependencies()
        let sessionService = SessionService()
        let coordinator = AppCoordinator(deps: deps, sessionService: sessionService)

        coordinator.handleAuthenticationChange(isAuthenticated: false)
        let firstAuthGeneration = coordinator.authCoordinatorGeneration

        coordinator.handleAuthenticationChange(isAuthenticated: true)
        let firstMainGeneration = coordinator.mainCoordinatorGeneration

        coordinator.handleAuthenticationChange(isAuthenticated: false)

        #expect(coordinator.authCoordinatorGeneration == firstAuthGeneration + 1)
        #expect(coordinator.mainCoordinator == nil)
        #expect(coordinator.mainCoordinatorGeneration == firstMainGeneration)
    }

    @Test func ignoresDuplicateAuthenticationState() {
        let deps = AppDependencies()
        let sessionService = SessionService()
        let coordinator = AppCoordinator(deps: deps, sessionService: sessionService)

        coordinator.handleAuthenticationChange(isAuthenticated: false)
        coordinator.handleAuthenticationChange(isAuthenticated: false)

        #expect(coordinator.authCoordinatorGeneration == 1)
    }
}
