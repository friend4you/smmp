//
//  RouterTests.swift
//  smmpTests
//

import SwiftUI
import Testing
@testable import smmp

private enum TestRoute: AppRoute {
    case first
    case second
}

@MainActor
struct RouterTests {

    @Test func pushIncrementsPath() {
        let router = Router<TestRoute>()
        #expect(router.path.isEmpty)

        router.push(.first)
        #expect(router.path.count == 1)

        router.push(.second)
        #expect(router.path.count == 2)
    }

    @Test func popDecrementsPath() {
        let router = Router<TestRoute>()
        router.push(.first)
        router.push(.second)

        router.pop()
        #expect(router.path.count == 1)

        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test func popToRootClearsPath() {
        let router = Router<TestRoute>()
        router.push(.first)
        router.push(.second)

        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    @Test func sheetPresentAndDismiss() {
        let router = Router<TestRoute>()
        #expect(router.sheet == nil)

        router.presentSheet(.first)
        #expect(router.sheet == .first)

        router.dismissSheet()
        #expect(router.sheet == nil)
    }

    @Test func resetClearsPathAndModals() {
        let router = Router<TestRoute>()
        router.push(.first)
        router.presentSheet(.second)
        router.presentFullScreenCover(.first)

        router.reset()

        #expect(router.path.isEmpty)
        #expect(router.sheet == nil)
        #expect(router.fullScreenCover == nil)
    }
}
