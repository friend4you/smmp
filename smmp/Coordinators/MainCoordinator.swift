//
//  MainCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class MainCoordinator: ObservableObject {
    @Published var selectedTab: Tab = .feed

    let feedCoordinator: FeedCoordinator
    let searchCoordinator: SearchCoordinator
    let newPostCoordinator: NewPostCoordinator
    let profileCoordinator: ProfileCoordinator

    init(deps: AppDependencies, sessionService: SessionService) {
        let tabSelector = TabSelector()
        feedCoordinator = FeedCoordinator(deps: deps, sessionService: sessionService)
        searchCoordinator = SearchCoordinator()
        profileCoordinator = ProfileCoordinator(deps: deps)
        newPostCoordinator = NewPostCoordinator(deps: deps) { tab in
            tabSelector.selectTab?(tab)
        }
        tabSelector.selectTab = { [weak self] tab in
            self?.selectTab(tab)
        }
    }

    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }

    func resetNavigation() {
        feedCoordinator.router.reset()
        searchCoordinator.router.reset()
        newPostCoordinator.router.reset()
        profileCoordinator.router.reset()
    }

    var rootView: some View {
        MainCoordinatorView(coordinator: self)
    }
}

private final class TabSelector {
    var selectTab: ((Tab) -> Void)?
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
