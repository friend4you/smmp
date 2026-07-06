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
final class SessionService: SessionServiceProtocol, ObservableObject {

    @Published private(set) var currentUser: User?

    private(set) var sessionState: AuthSession = .idle

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
        sessionState = .loading
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            Task { @MainActor in
                guard let user = firebaseUser else {
                    self.currentUser = nil
                    self.sessionState = .failure
                    return
                }
                self.currentUser = User(firebaseUser: user)
                self.sessionState = .success
            }
        }
    }
}
