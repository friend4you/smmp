//
//  smmpApp.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import SwiftUI
import Firebase

@main
struct smmpApp: App {
    let dependencies: AppDependencies
    
    init() {
        FirebaseApp.configure()
        self.dependencies = AppDependencies()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
        }
    }
}
