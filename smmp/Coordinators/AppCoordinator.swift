//
//  AppCoordinator.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published private(set) var authCoordinator: AuthCoordinator?
    @Published private(set) var mainCoordinator: MainCoordinator?
    @Published private(set) var authCoordinatorGeneration = 0
    @Published private(set) var mainCoordinatorGeneration = 0

    private let deps: AppDependencies
    private let sessionService: SessionService
    private var lastAuthenticated: Bool?

    init(deps: AppDependencies, sessionService: SessionService) {
        self.deps = deps
        self.sessionService = sessionService
    }

    var rootView: some View {
        AppCoordinatorView(coordinator: self, sessionService: sessionService)
    }

    func handleAuthenticationChange(isAuthenticated: Bool) {
        guard lastAuthenticated != isAuthenticated else { return }
        lastAuthenticated = isAuthenticated

        if isAuthenticated {
            authCoordinator = nil
            mainCoordinator = MainCoordinator(deps: deps, sessionService: sessionService)
            mainCoordinatorGeneration += 1
        } else {
            mainCoordinator = nil
            authCoordinator = AuthCoordinator(deps: deps)
            authCoordinatorGeneration += 1
        }
    }

    func bootstrapSessionState() {
        handleAuthenticationChange(isAuthenticated: sessionService.isAuthenticated)
    }
}

private struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var sessionService: SessionService

    var body: some View {
        Group {
            if sessionService.isResolvingSession {
                SplashView()
            } else if sessionService.isAuthenticated {
                if let mainCoordinator = coordinator.mainCoordinator {
                    mainCoordinator.rootView
                        .id(coordinator.mainCoordinatorGeneration)
                }
            } else if let authCoordinator = coordinator.authCoordinator {
                authCoordinator.rootView
                    .id(coordinator.authCoordinatorGeneration)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: sessionService.isResolvingSession)
        .onAppear {
            coordinator.bootstrapSessionState()
        }
        .onChange(of: sessionService.isAuthenticated) { _, isAuthenticated in
            coordinator.handleAuthenticationChange(isAuthenticated: isAuthenticated)
        }
    }
}
