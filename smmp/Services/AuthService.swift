//
//  AuthService.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import FirebaseAuth
import FirebaseFirestore

class AuthService: AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User {
        let authResult = try await performAuthOperation { completion in
            Auth.auth().signIn(withEmail: email, password: password, completion: completion)
        }
        return User(firebaseUser: authResult.user)
    }

    func register(displayName: String, email: String, password: String) async throws -> User {
        let authResult = try await performAuthOperation { completion in
            Auth.auth().createUser(withEmail: email, password: password, completion: completion)
        }

        do {
            try await updateDisplayName(displayName, for: authResult.user)
            try await reloadUser(authResult.user)
            var user = User(firebaseUser: authResult.user)
            user.bio = ""
            
            try await createProfile(
                uid: user.id,
                displayName: displayName,
                email: email
            )
            return user
        } catch {
            try? await deleteCurrentUser()
            throw error
        }
    }

    func signOut() async throws {
        try Auth.auth().signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func createProfile(uid: String, displayName: String, email: String) async throws {
        let data: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "bio": "",
            "photoURL": NSNull(),
            "followerCount": 0,
            "followingCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(data)
    }

    func deleteCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func performAuthOperation(
        _ operation: (@escaping (AuthDataResult?, Error?) -> Void) -> Void
    ) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            operation { authResult, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let authResult {
                    continuation.resume(returning: authResult)
                } else {
                    continuation.resume(throwing: AuthServiceError.missingAuthResult)
                }
            }
        }
    }

    private func updateDisplayName(_ displayName: String, for user: FirebaseAuth.User) async throws {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            changeRequest.commitChanges { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func reloadUser(_ user: FirebaseAuth.User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.reload { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

private enum AuthServiceError: Error {
    case missingAuthResult
}
