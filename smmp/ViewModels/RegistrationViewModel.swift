//
//  RegistrationViewModel.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/7/26.
//

import Combine
import Foundation

@MainActor
class RegistrationViewModel: ObservableObject {

    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var repeatPassword: String = ""

    @Published var isDisplayNameValid: Bool = true
    @Published var isEmailValid: Bool = true
    @Published var isPasswordValid: Bool = true
    @Published var isRepeatPasswordValid: Bool = true
    @Published var passwordStrength: FormValidation.PasswordStrength?
    @Published var shouldShowErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    @Published var isSubmitting: Bool = false

    private let authRepository: AuthRepositoryProtocol
    private let localRepository: LocalRepositoryProtocol
    private let onNavigate: (AuthRoute) -> Void

    init(
        authRepository: AuthRepositoryProtocol,
        localRepository: LocalRepositoryProtocol,
        onNavigate: @escaping (AuthRoute) -> Void = { _ in }
    ) {
        self.authRepository = authRepository
        self.localRepository = localRepository
        self.onNavigate = onNavigate
    }

    func register() async {
        shouldShowErrorMessage = false

        guard validateInputs() else {
            shouldShowErrorMessage = true
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let normalizedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let user = try await authRepository.register(
                displayName: normalizedDisplayName,
                email: normalizedEmail,
                password: password
            )
            try await localRepository.saveUser(user: user)
        } catch {
            errorMessage = AuthErrorMapper.message(for: error)
            shouldShowErrorMessage = true
        }
    }

    func updatePasswordStrength() {
        passwordStrength = FormValidation.passwordStrength(password)
    }

    @discardableResult
    private func validateInputs() -> Bool {
        let normalizedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        isDisplayNameValid = !normalizedDisplayName.isEmpty
        isEmailValid = FormValidation.isValidEmail(normalizedEmail)
        isPasswordValid = FormValidation.isValidPassword(password)
        isRepeatPasswordValid = password == repeatPassword

        if !isDisplayNameValid {
            errorMessage = String(localized: .authValidationDisplayNameRequired)
            return false
        }
        if !isEmailValid {
            errorMessage = String(localized: .authValidationEmailInvalid)
            return false
        }
        if !isPasswordValid {
            errorMessage = String(localized: .authValidationPasswordTooShort)
            return false
        }
        if !isRepeatPasswordValid {
            errorMessage = String(localized: .authValidationPasswordMismatch)
            return false
        }
        return true
    }
}
