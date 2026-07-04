//
//  AppCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

enum AppRootState {
    case splash
    case auth
    case main
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published private(set) var rootState: AppRootState = .splash
    @Published private(set) var authCoordinator: AuthCoordinator?
    @Published private(set) var mainCoordinator: MainCoordinator?

    private let deps: AppDependencies
    private var lastAuthenticated: Bool?

    init(deps: AppDependencies) {
        self.deps = deps
    }

    var rootView: some View {
        AppCoordinatorView(coordinator: self, sessionService: deps.sessionService)
    }

    func handleAuthenticationChange(isAuthenticated: Bool) {
        guard lastAuthenticated != isAuthenticated else { return }
        lastAuthenticated = isAuthenticated

        if isAuthenticated {
            authCoordinator?.router.reset()
            authCoordinator = nil
            mainCoordinator = MainCoordinator(deps: deps)
            rootState = .main
        } else if !deps.sessionService.isResolvingSession {
            mainCoordinator?.resetNavigation()
            mainCoordinator = nil
            deps.postRepository.removeAllListeners()
            authCoordinator = AuthCoordinator(deps: deps)
            rootState = .auth
        }
    }

    func onCoordinatorStart() {
        handleAuthenticationChange(isAuthenticated: deps.sessionService.isAuthenticated)
    }
}

private struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var sessionService: SessionService
    
    var body: some View {
        Group {
            switch coordinator.rootState {
            case .splash:
                SplashView()
            case .auth:
                coordinator.authCoordinator?.rootView
            case .main:
                coordinator.mainCoordinator?.rootView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: sessionService.isResolvingSession)
        .onAppear {
            coordinator.onCoordinatorStart()
        }
        .onChange(of: sessionService.isAuthenticated) { _, isAuthenticated in
            coordinator.handleAuthenticationChange(isAuthenticated: isAuthenticated)
        }
    }
}
