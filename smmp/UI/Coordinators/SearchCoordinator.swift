//
//  SearchCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class SearchCoordinator: Coordinating, ObservableObject {
    let router = SearchRouter()
    private let builder: SearchViewBuilder

    init(deps: AppDependenciesProviding) {
        builder = SearchViewBuilder(deps: deps)
    }

    var rootView: some View {
        SearchCoordinatorView(coordinator: self)
    }

    fileprivate func navigate(_ route: SearchRoute) {
        switch route {
        case .editProfile:
            router.presentSheet(route)
        default:
            router.push(route)
        }
    }

    fileprivate func searchView() -> some View {
        builder.build(.search, onNavigate: navigate)
    }

    @ViewBuilder
    fileprivate func buildView(for route: SearchRoute) -> some View {
        builder.build(route, onNavigate: navigate)
    }
}

private struct SearchCoordinatorView: View {
    @ObservedObject var coordinator: SearchCoordinator
    @ObservedObject private var router: SearchRouter

    init(coordinator: SearchCoordinator) {
        self.coordinator = coordinator
        _router = ObservedObject(wrappedValue: coordinator.router)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            coordinator.searchView()
                .navigationDestination(for: SearchRoute.self) { route in
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
