//
//  Router.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class Router<Route: AppRoute>: Routing, ObservableObject {
    @Published var path = NavigationPath()
    @Published var sheet: Route?
    @Published var fullScreenCover: Route?

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func presentSheet(_ route: Route) {
        sheet = route
    }

    func dismissSheet() {
        sheet = nil
    }

    func presentFullScreenCover(_ route: Route) {
        fullScreenCover = route
    }

    func dismissFullScreenCover() {
        fullScreenCover = nil
    }

    func reset() {
        popToRoot()
        dismissSheet()
        dismissFullScreenCover()
    }
}
