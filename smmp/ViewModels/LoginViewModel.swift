//
//  LoginViewModel.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import Combine
import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isEmailValid: Bool = true
    @Published var isPasswordValid: Bool = true
    @Published var shouldShowErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    @Published var isSubmitting: Bool = false

    private let authRepository: AuthRepositoryProtocol
    private let localRepository: LocalRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol, localRepository: LocalRepositoryProtocol) {
        self.authRepository = authRepository
        self.localRepository = localRepository
    }

    func login() async {
        shouldShowErrorMessage = false

        guard validateInputs() else {
            shouldShowErrorMessage = true
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let user = try await authRepository.login(email: normalizedEmail, password: password)
            try await localRepository.saveUser(user: user)
        } catch {
            errorMessage = AuthErrorMapper.message(for: error)
            shouldShowErrorMessage = true
        }
    }

    @discardableResult
    private func validateInputs() -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        isEmailValid = FormValidation.isValidEmail(normalizedEmail)
        isPasswordValid = !password.isEmpty

        if !isEmailValid {
            errorMessage = String(localized: .authValidationEmailInvalid)
            return false
        }
        if !isPasswordValid {
            errorMessage = String(localized: .authValidationPasswordRequired)
            return false
        }
        return true
    }
}
