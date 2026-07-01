//
//  smmpApp.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import SwiftUI
import Firebase

@main
struct SMMPApp: App {
    let dependencies: AppDependencies
    let sessionService: SessionService
    let appCoordinator: AppCoordinator

    init() {
        FirebaseApp.configure()
        self.dependencies = AppDependencies()
        self.sessionService = SessionService()
        self.appCoordinator = AppCoordinator(deps: dependencies, sessionService: sessionService)
    }

    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView
                .environmentObject(dependencies)
                .environmentObject(sessionService)
        }
    }
}
