//
//  RegistrationViewModel.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/7/26.
//

import Combine
import Foundation

class RegistrationViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var repeatPassword: String = ""
    
    private let authRepository: AuthRepositoryProtocol
    private let localRepository: LocalRepositoryProtocol

    
    init(authRepository: AuthRepositoryProtocol,
         localRepository: LocalRepositoryProtocol) {
        self.authRepository = authRepository
        self.localRepository = localRepository
    }
    
    func register() async {
        try? await authRepository.register(email: email, password: password) { result in
            switch result {
            case .success(let user):
                Task {
                    try? await self.localRepository.saveUser(user: user)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
