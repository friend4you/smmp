//
//  SessionService.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SessionService: ObservableObject {

    @Published private(set) var currentUser: User?
    @Published private(set) var isResolvingSession: Bool = true

    var isAuthenticated: Bool { currentUser != nil }

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        attachListener()
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func attachListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            Task { @MainActor in
                defer {
                    self.isResolvingSession = false
                }
                
                guard let user = firebaseUser else {
                    self.currentUser = nil
                     return
                }
                self.currentUser = User(firebaseUser: user)
            }
        }
    }
}
