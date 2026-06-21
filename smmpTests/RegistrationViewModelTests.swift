//
//  RegistrationViewModelTests.swift
//  smmpTests
//

import Testing
@testable import smmp

@MainActor
struct RegistrationViewModelTests {

    @Test func passwordMismatchDoesNotCallAuth() async {
        let authRepository = MockAuthRepository()
        let localRepository = MockLocalRepository()
        let viewModel = RegistrationViewModel(
            authRepository: authRepository,
            localRepository: localRepository
        )

        viewModel.displayName = "Alice"
        viewModel.email = "alice@example.com"
        viewModel.password = "secret123"
        viewModel.repeatPassword = "different"
        await viewModel.register()

        #expect(authRepository.registerCallCount == 0)
        #expect(viewModel.shouldShowErrorMessage)
        #expect(!viewModel.isRepeatPasswordValid)
    }

    @Test func successCallsRegisterWithDisplayName() async {
        let authRepository = MockAuthRepository()
        authRepository.registerResult = .success(makeUser(displayName: "Alice", email: "alice@example.com"))
        let localRepository = MockLocalRepository()
        let viewModel = RegistrationViewModel(
            authRepository: authRepository,
            localRepository: localRepository
        )

        viewModel.displayName = "Alice"
        viewModel.email = "alice@example.com"
        viewModel.password = "secret123"
        viewModel.repeatPassword = "secret123"
        await viewModel.register()

        #expect(authRepository.registerCallCount == 1)
        #expect(authRepository.lastRegisterDisplayName == "Alice")
        #expect(authRepository.lastRegisterEmail == "alice@example.com")
        #expect(localRepository.savedUsers.count == 1)
        #expect(!viewModel.shouldShowErrorMessage)
    }
}
