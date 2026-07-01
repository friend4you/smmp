//
//  MainCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class MainCoordinator: ObservableObject {
    @Published var selectedTab: Tab = .feed

    private let deps: AppDependencies

    let feedCoordinator: FeedCoordinator
    let searchCoordinator: SearchCoordinator
    lazy var newPostCoordinator: NewPostCoordinator = NewPostCoordinator(deps: deps) { [weak self] tab in
        self?.selectTab(tab)
    }
    let profileCoordinator: ProfileCoordinator

    init(deps: AppDependencies, sessionService: SessionService) {
        self.deps = deps
        feedCoordinator = FeedCoordinator(deps: deps, sessionService: sessionService)
        searchCoordinator = SearchCoordinator()
        profileCoordinator = ProfileCoordinator(deps: deps)
    }

    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }

    var rootView: some View {
        MainCoordinatorView(coordinator: self)
    }
}

private struct MainCoordinatorView: View {
    @ObservedObject var coordinator: MainCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            coordinator.feedCoordinator.rootView
                .tabItem { Label(.tabHome, systemImage: "house") }
                .tag(Tab.feed)
            coordinator.searchCoordinator.rootView
                .tabItem { Label(.tabSearch, systemImage: "magnifyingglass") }
                .tag(Tab.search)
            coordinator.newPostCoordinator.rootView
                .tabItem { Label(.tabPost, systemImage: "plus.square") }
                .tag(Tab.newPost)
            coordinator.profileCoordinator.rootView
                .tabItem { Label(.tabProfile, systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)
        }
    }
}
