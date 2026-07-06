//
//  ProfileViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct ProfileViewBuilder {
    let deps: AppDependenciesProviding

    private func buildProfile(onNavigate: @escaping (ProfileRoute) -> Void) -> ProfileView {
        ProfileView(
            viewModel: ProfileViewModel(
                authRepository: deps.authRepository,
                profileRepository: deps.profileRepository,
                sessionService: deps.sessionService,
                onNavigate: onNavigate
            )
        )
    }
    
    private func buildEditProfile(onNavigate: @escaping (ProfileRoute) -> Void) -> EditProfileView {
        EditProfileView()
    }

    @ViewBuilder
    func build(_ route: ProfileRoute, onNavigate: @escaping (ProfileRoute) -> Void) -> some View {
        switch route {
        case .profile:
            buildProfile(onNavigate: onNavigate)
        case .editProfile:
            buildEditProfile(onNavigate: onNavigate)
        }
    }
}
