//
//  ProfileViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct ProfileViewBuilder {
    let deps: AppDependencies

    func buildProfile(onNavigate: @escaping (ProfileRoute) -> Void) -> ProfileView {
        ProfileView(
            viewModel: ProfileViewModel(
                authRepository: deps.authRepository,
                postRepository: deps.postRepository,
                onNavigate: onNavigate
            )
        )
    }

    @ViewBuilder
    func build(_ route: ProfileRoute, onNavigate: @escaping (ProfileRoute) -> Void) -> some View {
        switch route {
        case .profile:
            buildProfile(onNavigate: onNavigate)
        case .editProfile:
            EditProfilePlaceholderView()
        }
    }
}

private struct EditProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(label: { Text(.profileEdit) })
                .navigationTitle(Text(.profileEdit))
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
