//
//  RegistrationViewModelTests.swift
//  smmpTests
//

import Testing
@testable import smmp

@MainActor
struct RegistrationViewModelTests {

    @Test func passwordMismatchDoesNotCallAuth() async {
        let viewModel = makeViewModel()

        viewModel.displayName = "Alice"
        viewModel.email = "alice@example.com"
        viewModel.password = "secret123"
        viewModel.repeatPassword = "different"
        await viewModel.register()

        #expect(viewModel.authRepository.registerCallCount == 0)
        #expect(viewModel.profileRepository.createProfileCallCount == 0)
        #expect(viewModel.shouldShowErrorMessage)
        #expect(!viewModel.isRepeatPasswordValid)
    }

    @Test func successBootstrapsProfileAfterAuth() async {
        let viewModel = makeViewModel()
        viewModel.authRepository.registerResult = .success(makeUser(id: "uid-1"))
        viewModel.profileRepository.createProfileResult = .success(
            makeUser(id: "uid-1", displayName: "Alice", email: "alice@example.com")
        )

        viewModel.displayName = "Alice"
        viewModel.email = "alice@example.com"
        viewModel.password = "secret123"
        viewModel.repeatPassword = "secret123"
        await viewModel.register()

        #expect(viewModel.authRepository.registerCallCount == 1)
        #expect(viewModel.authRepository.lastRegisterDisplayName == "Alice")
        #expect(viewModel.authRepository.lastRegisterEmail == "alice@example.com")
        #expect(viewModel.profileRepository.createProfileCallCount == 1)
        #expect(viewModel.profileRepository.lastCreateUid == "uid-1")
        #expect(viewModel.localRepository.savedUsers.count == 1)
        #expect(viewModel.accountDeleter.deleteCallCount == 0)
        #expect(!viewModel.shouldShowErrorMessage)
    }

    @Test func profileBootstrapFailureRollsBackAuthAccount() async {
        let viewModel = makeViewModel()
        viewModel.authRepository.registerResult = .success(makeUser(id: "uid-2"))
        viewModel.profileRepository.createProfileResult = .failure(MockAuthError.notConfigured)

        viewModel.displayName = "Bob"
        viewModel.email = "bob@example.com"
        viewModel.password = "secret123"
        viewModel.repeatPassword = "secret123"
        await viewModel.register()

        #expect(viewModel.authRepository.registerCallCount == 1)
        #expect(viewModel.profileRepository.createProfileCallCount == 1)
        #expect(viewModel.accountDeleter.deleteCallCount == 1)
        #expect(viewModel.localRepository.savedUsers.isEmpty)
        #expect(viewModel.shouldShowErrorMessage)
    }

    // MARK: - Helpers

    private func makeViewModel() -> RegistrationViewModelHarness {
        RegistrationViewModelHarness(
            authRepository: MockAuthRepository(),
            profileRepository: MockRegistrationProfileRepository(),
            accountDeleter: MockAccountDeleter(),
            localRepository: MockLocalRepository()
        )
    }
}

// MARK: - Harness

@MainActor
private final class RegistrationViewModelHarness: RegistrationViewModel {
    let authRepository: MockAuthRepository
    let profileRepository: MockRegistrationProfileRepository
    let accountDeleter: MockAccountDeleter
    let localRepository: MockLocalRepository

    init(
        authRepository: MockAuthRepository,
        profileRepository: MockRegistrationProfileRepository,
        accountDeleter: MockAccountDeleter,
        localRepository: MockLocalRepository
    ) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.accountDeleter = accountDeleter
        self.localRepository = localRepository
        super.init(
            authRepository: authRepository,
            profileRepository: profileRepository,
            accountDeleter: accountDeleter,
            localRepository: localRepository
        )
    }
}

private final class MockRegistrationProfileRepository: ProfileRepositoryProtocol {
    var createProfileResult: Result<User, Error>?
    private(set) var createProfileCallCount = 0
    private(set) var lastCreateUid: String?

    func createProfile(uid: String, displayName: String, email: String) async throws -> User {
        createProfileCallCount += 1
        lastCreateUid = uid
        switch createProfileResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        case .none:
            throw MockAuthError.notConfigured
        }
    }

    func fetchUser(id: String) async throws -> User? {
        nil
    }
}

private final class MockAccountDeleter: AuthAccountDeleting {
    private(set) var deleteCallCount = 0

    func deleteCurrentUser() async throws {
        deleteCallCount += 1
    }
}
