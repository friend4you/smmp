//
//  AppCoordinatorTests.swift
//  smmpTests
//

import SwiftUI
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

    @Test func logoutResetsMainNavigationBeforeDiscard() {
        let deps = AppDependencies()
        let coordinator = AppCoordinator(deps: deps, sessionService: SessionService())

        coordinator.handleAuthenticationChange(isAuthenticated: true)
        let mainCoordinator = coordinator.mainCoordinator
        mainCoordinator?.feedCoordinator.router.push(.postDetail(makeFeedPostItem()))

        coordinator.handleAuthenticationChange(isAuthenticated: false)

        #expect(coordinator.mainCoordinator == nil)
        #expect(mainCoordinator?.feedCoordinator.router.path.isEmpty == true)
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
