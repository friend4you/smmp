//
//  MockRouter.swift
//  smmpTests
//

import Combine
import SwiftUI
@testable import smmp

@MainActor
final class MockRouter<Route: AppRoute>: Routing, ObservableObject {
    @Published var path = NavigationPath()
    @Published var sheet: Route?
    @Published var fullScreenCover: Route?

    private(set) var pushCallCount = 0
    private(set) var popCallCount = 0
    private(set) var popToRootCallCount = 0
    private(set) var presentSheetCallCount = 0
    private(set) var dismissSheetCallCount = 0
    private(set) var presentFullScreenCoverCallCount = 0
    private(set) var dismissFullScreenCoverCallCount = 0
    private(set) var resetCallCount = 0
    private(set) var lastPushedRoute: Route?
    private(set) var lastPresentedSheetRoute: Route?

    func push(_ route: Route) {
        pushCallCount += 1
        lastPushedRoute = route
        path.append(route)
    }

    func pop() {
        popCallCount += 1
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        popToRootCallCount += 1
        path = NavigationPath()
    }

    func presentSheet(_ route: Route) {
        presentSheetCallCount += 1
        lastPresentedSheetRoute = route
        sheet = route
    }

    func dismissSheet() {
        dismissSheetCallCount += 1
        sheet = nil
    }

    func presentFullScreenCover(_ route: Route) {
        presentFullScreenCoverCallCount += 1
        fullScreenCover = route
    }

    func dismissFullScreenCover() {
        dismissFullScreenCoverCallCount += 1
        fullScreenCover = nil
    }

    func reset() {
        resetCallCount += 1
        popToRoot()
        dismissSheet()
        dismissFullScreenCover()
    }
}
