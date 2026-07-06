//
//  MockRouterTests.swift
//  smmpTests
//

import SwiftUI
import Testing
@testable import smmp

private enum MockTestRoute: AppRoute {
    case destination
}

@MainActor
struct MockRouterTests {

    @Test func pushTracksRouteWithoutNavigationStack() {
        let router = MockRouter<MockTestRoute>()

        router.push(.destination)

        #expect(router.pushCallCount == 1)
        #expect(router.lastPushedRoute == .destination)
        #expect(router.path.count == 1)
    }

    @Test func resetClearsAllPresentationState() {
        let router = MockRouter<MockTestRoute>()
        router.push(.destination)
        router.presentSheet(.destination)
        router.presentFullScreenCover(.destination)

        router.reset()

        #expect(router.resetCallCount == 1)
        #expect(router.path.isEmpty)
        #expect(router.sheet == nil)
        #expect(router.fullScreenCover == nil)
    }

    @Test func loginViewModelNavigateUsesInjectedRouter() {
        let router = MockRouter<AuthRoute>()
        let viewModel = LoginViewModel(
            authRepository: MockAuthRepository(),
            localRepository: MockLocalRepository(),
            onNavigate: { router.push($0) }
        )

        viewModel.navigateToRegister()

        #expect(router.pushCallCount == 1)
        #expect(router.lastPushedRoute == .register)
    }
}
