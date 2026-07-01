//
//  ProfileViewModel.swift
//  smmp
//

import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    private let authRepository: AuthRepositoryProtocol
    private let postRepository: PostRepositoryProtocol
    private let onNavigate: (ProfileRoute) -> Void

    init(
        authRepository: AuthRepositoryProtocol,
        postRepository: PostRepositoryProtocol,
        onNavigate: @escaping (ProfileRoute) -> Void = { _ in }
    ) {
        self.authRepository = authRepository
        self.postRepository = postRepository
        self.onNavigate = onNavigate
    }

    func editProfileTapped() {
        onNavigate(.editProfile)
    }

    func logout() async {
        postRepository.removeAllListeners()
        try? await authRepository.signOut()
    }
}
