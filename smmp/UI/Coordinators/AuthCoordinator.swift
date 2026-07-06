//
//  AuthCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class AuthCoordinator: Coordinating {
    let router = AuthRouter()
    private let builder: AuthViewBuilder

    init(deps: AppDependenciesProviding) {
        builder = AuthViewBuilder(deps: deps)
    }

    var rootView: some View {
        AuthCoordinatorView(coordinator: self)
    }

    func navigate(_ route: AuthRoute) {
        switch route {
        case .register, .forgotPassword:
            router.push(route)
        case .login:
            router.popToRoot()
        }
    }

    @ViewBuilder
    fileprivate func buildView(for route: AuthRoute) -> some View {
        builder.build(route, onNavigate: navigate)
    }
}

private struct AuthCoordinatorView: View {
    @ObservedObject var coordinator: AuthCoordinator
    @ObservedObject private var router: AuthRouter

    init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
        _router = ObservedObject(wrappedValue: coordinator.router)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            coordinator.buildView(for: .login)
                .navigationDestination(for: AuthRoute.self) { route in
                    coordinator.buildView(for: route)
                }
        }
        .sheet(item: $router.sheet) { route in
            coordinator.buildView(for: route)
        }
        .fullScreenCover(item: $router.fullScreenCover) { route in
            coordinator.buildView(for: route)
        }
    }
}
