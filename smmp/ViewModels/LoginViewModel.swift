//
//  LoginViewModel.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import Combine
import Foundation

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var isEmailValid: Bool = true
    @Published var isPasswordValid: Bool = true
    @Published var shouldShowErrorMessage: Bool = false
    @Published var errorMessage: String = "Error"
    
    private let authRepository: AuthRepository
    private let localRepository: LocalRepositoryProtocol
    
    init(authRepository: AuthRepository, localRepository: LocalRepositoryProtocol) {
        self.authRepository = authRepository
        self.localRepository = localRepository
    }
    
    @MainActor
    func login() async {
        guard isEmailValid, isPasswordValid else {
            shouldShowErrorMessage = true
            return
        }

        try? await authRepository.login(email: email, password: password) { result in
            switch result {
            case .success(let user):
                Task {
                    try? await self.localRepository.saveUser(user: user)
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.shouldShowErrorMessage = true
                return
            }
        }
    }
}
