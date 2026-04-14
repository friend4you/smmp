//
//  AuthService.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import FirebaseAuth

class AuthService: AuthServiceProtocol {
    func login(email: String, password: String, completion: @escaping ((Result<User, Error>) -> Void)) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard let authResult = authResult else {
                if let error = error {
                    completion(.failure(error))
                }
                return
            }
            let user = User(firebaseUser: authResult.user)
            completion(.success(user))
        }
    }
    
    func register(email: String, password: String, completion: @escaping ((Result<User, Error>) -> Void)) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard let authResult = authResult else {
                if let error = error {
                    completion(.failure(error))
                }
                return
            }
            let user = User(firebaseUser: authResult.user)
            completion(.success(user))
        }
    }
}
