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
        let coordinator = AppCoordinator(deps: AppDependencies())

        coordinator.handleAuthenticationChange(authState: .failure)

        #expect(coordinator.authCoordinator != nil)
        #expect(coordinator.mainCoordinator == nil)
        #expect(coordinator.rootState == .auth)
    }

    @Test func createsMainCoordinatorWhenAuthenticated() {
        let coordinator = AppCoordinator(deps: AppDependencies())

        coordinator.handleAuthenticationChange(authState: .success)

        #expect(coordinator.mainCoordinator != nil)
        #expect(coordinator.authCoordinator == nil)
        #expect(coordinator.rootState == .main)
    }

    @Test func recreatesCoordinatorsOnAuthTransition() {
        let coordinator = AppCoordinator(deps: AppDependencies())

        coordinator.handleAuthenticationChange(authState: .failure)
        let firstAuthCoordinator = coordinator.authCoordinator

        coordinator.handleAuthenticationChange(authState: .success)
        let firstMainCoordinator = coordinator.mainCoordinator

        coordinator.handleAuthenticationChange(authState: .failure)

        #expect(coordinator.authCoordinator !== firstAuthCoordinator)
        #expect(coordinator.mainCoordinator == nil)
        #expect(firstMainCoordinator?.feedCoordinator.router.path.isEmpty == true)
    }

    @Test func logoutResetsMainNavigationBeforeDiscard() {
        let coordinator = AppCoordinator(deps: AppDependencies())

        coordinator.handleAuthenticationChange(authState: .success)
        let mainCoordinator = coordinator.mainCoordinator
        mainCoordinator?.feedCoordinator.router.push(.postDetail(makeFeedPostItem()))

        coordinator.handleAuthenticationChange(authState: .failure)

        #expect(coordinator.mainCoordinator == nil)
        #expect(mainCoordinator?.feedCoordinator.router.path.isEmpty == true)
    }

    @Test func ignoresIdleAndLoadingStates() {
        let coordinator = AppCoordinator(deps: AppDependencies())

        coordinator.handleAuthenticationChange(authState: .idle)
        coordinator.handleAuthenticationChange(authState: .loading)

        #expect(coordinator.rootState == .splash)
        #expect(coordinator.authCoordinator == nil)
        #expect(coordinator.mainCoordinator == nil)
    }
}
