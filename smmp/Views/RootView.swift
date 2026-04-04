//
//  RootView.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var deps: AppDependencies
    
    var body: some View {
        if deps.sessionService.isResolvingSession {
            //TODO: SplashView()
        } else if deps.sessionService.isAuthenticated {
            //TODO: MainTabView()
        } else {
            //TODO: AuthFlowView()
        }
        
        Text("Resolving authentication...")
    }
}
