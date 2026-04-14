//
//  AuthRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

protocol AuthRepositoryProtocol {
    func login(email: String, password: String, completion: @escaping ((Result<User, Error>) -> Void)) async throws
    func register(email: String, password: String, completion: @escaping ((Result<User, Error>) -> Void)) async throws
}

class AuthRepository: AuthRepositoryProtocol {
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func login(email: String, password: String, completion: @escaping (Result<User, any Error>) -> Void) async throws {
        authService.login(email: email, password: password) { result in
            switch result {
            case .success(let user):
                completion(.success(user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func register(email: String, password: String, completion: @escaping ((Result<User, Error>) -> Void)) async throws {
        authService.register(email: email, password: password) { result in
            switch result {
            case .success(let user):
                completion(.success(user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
