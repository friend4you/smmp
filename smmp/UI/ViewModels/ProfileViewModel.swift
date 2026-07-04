//
//  ProfileViewModel.swift
//  smmp
//

import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var displayName: String?
    @Published var bio: String?
    
    private let authRepository: AuthRepositoryProtocol
    private let profileRepository: ProfileRepositoryProtocol
    private let sessionService: SessionService
    private let onNavigate: (ProfileRoute) -> Void
    private var user: User?

    init(
        authRepository: AuthRepositoryProtocol,
        profileRepository: ProfileRepositoryProtocol,
        sessionService: SessionService,
        onNavigate: @escaping (ProfileRoute) -> Void = { _ in }
    ) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.sessionService = sessionService
        self.onNavigate = onNavigate
    }
    
    func fetchProfile() {
        guard let userId = sessionService.currentUser?.id else { return }
        Task {
            do {
                user = try await self.profileRepository.fetchUser(id: userId)
                displayName = user?.displayName
                bio = user?.bio
            } catch(let error){
                print(error)
                //presentError(String(localized: .authErrorUserNotFound))
            }
        }
        
    }

    func editProfileTapped() {
        onNavigate(.editProfile)
    }

    func logout() async {
//        postRepository.removeAllListeners()
        try? await authRepository.signOut()
    }
}
