//
//  RootView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var deps: AppDependencies
    @EnvironmentObject private var sessionService: SessionService
    
    var body: some View {
        Group {
            if sessionService.isResolvingSession {
                Text("Resolving authentication...")
                //TODO: SplashView()
            } else if sessionService.isAuthenticated {
                ContentView()
            } else {
                LoginView(loginViewModel: LoginViewModel(authRepository: deps.authRepository,
                                                         localRepository: deps.localRepository))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: sessionService.isResolvingSession)
    }
}
