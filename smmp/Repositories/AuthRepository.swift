//
//  AuthRepository.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

class AuthRepository {
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
}
