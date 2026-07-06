//
//  MainCoordinatorTests.swift
//  smmpTests
//

import SwiftUI
import Testing
@testable import smmp

@MainActor
struct MainCoordinatorTests {

    @Test func tabSwitchPreservesFeedNavigationStack() {
        let coordinator = MainCoordinator(deps: AppDependencies())
        coordinator.feedCoordinator.router.push(.postDetail(makeFeedPostItem()))

        coordinator.selectTab(.search)
        coordinator.selectTab(.feed)

        #expect(coordinator.feedCoordinator.router.path.count == 1)
    }

    @Test func newPostSuccessSelectsFeedTab() {
        let coordinator = MainCoordinator(deps: AppDependencies())
        coordinator.selectTab(.newPost)

        coordinator.newPostCoordinator.handlePostCreated()

        #expect(coordinator.selectedTab == .feed)
    }

    @Test func resetNavigationClearsAllTabStacks() {
        let coordinator = MainCoordinator(deps: AppDependencies())
        coordinator.feedCoordinator.router.push(.postDetail(makeFeedPostItem()))
        coordinator.profileCoordinator.router.presentSheet(.editProfile)

        coordinator.resetNavigation()

        #expect(coordinator.feedCoordinator.router.path.isEmpty)
        #expect(coordinator.profileCoordinator.router.sheet == nil)
    }
}
