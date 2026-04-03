//
//  SessionService.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

// SessionStore.swift
import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SessionService: ObservableObject {

    @Published private(set) var currentUser: User? = nil
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
                self.currentUser = User()
                self.isResolvingSession = false
            }
        }
    }
}
