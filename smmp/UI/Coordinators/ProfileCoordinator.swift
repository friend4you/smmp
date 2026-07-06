//
//  ProfileCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class ProfileCoordinator: Coordinating, ObservableObject {
    let router = ProfileRouter()
    private let builder: ProfileViewBuilder

    init(deps: any AppDependenciesProviding) {
        builder = ProfileViewBuilder(deps: deps)
    }

    var rootView: some View {
        ProfileCoordinatorView(coordinator: self)
    }

    fileprivate func navigate(_ route: ProfileRoute) {
        switch route {
        case .editProfile:
            router.presentSheet(route)
        case .profile:
            router.push(route)
        }
    }

    @ViewBuilder
    fileprivate func buildView(for route: ProfileRoute) -> some View {
        builder.build(route, onNavigate: navigate)
    }
}

private struct ProfileCoordinatorView: View {
    @ObservedObject var coordinator: ProfileCoordinator
    @ObservedObject private var router: ProfileRouter

    init(coordinator: ProfileCoordinator) {
        self.coordinator = coordinator
        _router = ObservedObject(wrappedValue: coordinator.router)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            coordinator.buildView(for: .profile)
                .navigationDestination(for: ProfileRoute.self) { route in
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
