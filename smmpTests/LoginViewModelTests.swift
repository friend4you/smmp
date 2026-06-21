//
//  LoginViewModelTests.swift
//  smmpTests
//

import FirebaseAuth
import Testing
@testable import smmp

@MainActor
struct LoginViewModelTests {

    @Test func invalidEmailDoesNotCallAuth() async {
        let authRepository = MockAuthRepository()
        let localRepository = MockLocalRepository()
        let viewModel = LoginViewModel(
            authRepository: authRepository,
            localRepository: localRepository
        )

        viewModel.email = "not-an-email"
        viewModel.password = "secret123"
        await viewModel.login()

        #expect(authRepository.loginCallCount == 0)
        #expect(viewModel.shouldShowErrorMessage)
        #expect(!viewModel.isEmailValid)
    }

    @Test func authFailureSetsErrorMessage() async {
        let authRepository = MockAuthRepository()
        authRepository.loginResult = .failure(
            NSError(domain: AuthErrorDomain, code: AuthErrorCode.wrongPassword.rawValue)
        )
        let localRepository = MockLocalRepository()
        let viewModel = LoginViewModel(
            authRepository: authRepository,
            localRepository: localRepository
        )

        viewModel.email = "user@example.com"
        viewModel.password = "wrong"
        await viewModel.login()

        #expect(authRepository.loginCallCount == 1)
        #expect(viewModel.shouldShowErrorMessage)
        #expect(!viewModel.errorMessage.isEmpty)
    }
}
