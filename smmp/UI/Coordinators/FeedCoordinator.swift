//
//  FeedCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class FeedCoordinator: Coordinating, ObservableObject {
    let router = FeedRouter()
    private let builder: FeedViewBuilder

    init(deps: AppDependenciesProviding) {
        builder = FeedViewBuilder(deps: deps)
    }

    var rootView: some View {
        FeedCoordinatorView(coordinator: self)
    }

    fileprivate func navigate(_ route: FeedRoute) {
        router.push(route)
    }
    
    @ViewBuilder
    fileprivate func buildView(for route: FeedRoute) -> some View {
        builder.build(route, onNavigate: navigate)
    }
}

private struct FeedCoordinatorView: View {
    @ObservedObject var coordinator: FeedCoordinator
    @ObservedObject private var router: FeedRouter

    init(coordinator: FeedCoordinator) {
        self.coordinator = coordinator
        _router = ObservedObject(wrappedValue: coordinator.router)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            coordinator.buildView(for: .feed)
                .navigationDestination(for: FeedRoute.self) { route in
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
