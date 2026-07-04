//
//  NewPostCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class NewPostCoordinator: Coordinating, ObservableObject {
    let router = NewPostRouter()
    private let builder: NewPostViewBuilder
    private let onSelectTab: (Tab) -> Void

    init(deps: AppDependencies, onSelectTab: @escaping (Tab) -> Void) {
        builder = NewPostViewBuilder(deps: deps)
        self.onSelectTab = onSelectTab
    }

    var rootView: some View {
        NewPostCoordinatorView(coordinator: self)
    }

    fileprivate func handlePostCreated() {
        onSelectTab(.feed)
    }

    @ViewBuilder
    fileprivate func buildView(for route: NewPostRoute) -> some View {
        builder.build(route, onPostCreated: handlePostCreated)
    }
}

private struct NewPostCoordinatorView: View {
    @ObservedObject var coordinator: NewPostCoordinator
    @ObservedObject private var router: NewPostRouter

    init(coordinator: NewPostCoordinator) {
        self.coordinator = coordinator
        _router = ObservedObject(wrappedValue: coordinator.router)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            coordinator.buildView(for: .newPost)
                .navigationDestination(for: NewPostRoute.self) { route in
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
