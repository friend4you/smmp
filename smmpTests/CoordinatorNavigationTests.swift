//
//  CoordinatorNavigationTests.swift
//  smmpTests
//

import SwiftUI
import Testing
@testable import smmp

@MainActor
struct CoordinatorNavigationTests {

    @Test func authCoordinatorSupportsLoginRegisterForgotPasswordFlow() {
        let coordinator = AuthCoordinator(deps: AppDependencies())

        coordinator.navigate(.register)
        #expect(coordinator.router.path.count == 1)

        coordinator.navigate(.login)
        #expect(coordinator.router.path.isEmpty)

        coordinator.navigate(.forgotPassword)
        #expect(coordinator.router.path.count == 1)

        coordinator.navigate(.login)
        #expect(coordinator.router.path.isEmpty)
    }

    @Test func feedPostDetailPushAndPop() {
        let coordinator = FeedCoordinator(deps: AppDependencies())
        let item = makeFeedPostItem()

        coordinator.router.push(.postDetail(item))
        #expect(coordinator.router.path.count == 1)

        coordinator.router.pop()
        #expect(coordinator.router.path.isEmpty)
    }

    @Test func authenticatedToLogoutReturnsAuthCoordinator() {
        let appCoordinator = AppCoordinator(deps: AppDependencies())

        appCoordinator.handleAuthenticationChange(authState: .success)
        appCoordinator.mainCoordinator?.feedCoordinator.router.push(.postDetail(makeFeedPostItem()))

        appCoordinator.handleAuthenticationChange(authState: .failure)

        #expect(appCoordinator.mainCoordinator == nil)
        #expect(appCoordinator.authCoordinator != nil)
        #expect(appCoordinator.rootState == .auth)
    }
}
