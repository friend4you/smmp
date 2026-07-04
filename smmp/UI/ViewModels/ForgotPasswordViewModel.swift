//
//  ForgotPasswordViewModel.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/4/26.
//

import Combine
import Foundation

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var email: String = ""

    @Published var isEmailValid: Bool = true
    @Published var shouldShowErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    @Published var shouldShowSuccessMessage: Bool = false
    @Published var isSubmitting: Bool = false

    private let authRepository: AuthRepositoryProtocol
    private let onNavigate: (AuthRoute) -> Void

    init(
        authRepository: AuthRepositoryProtocol,
        onNavigate: @escaping (AuthRoute) -> Void = { _ in }
    ) {
        self.authRepository = authRepository
        self.onNavigate = onNavigate
    }

    func sendResetEmail() async {
        shouldShowErrorMessage = false
        shouldShowSuccessMessage = false

        guard validateEmail() else {
            shouldShowErrorMessage = true
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await authRepository.sendPasswordReset(email: normalizedEmail)
            shouldShowSuccessMessage = true
        } catch {
            errorMessage = AuthErrorMapper.message(for: error)
            shouldShowErrorMessage = true
        }
    }

    @discardableResult
    private func validateEmail() -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        isEmailValid = FormValidation.isValidEmail(normalizedEmail)
        if !isEmailValid {
            errorMessage = String(localized: .authValidationEmailInvalid)
        }
        return isEmailValid
    }
}
