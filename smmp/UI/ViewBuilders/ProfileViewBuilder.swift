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
                postRepository: deps.postRepository,
                localRepository: deps.localRepository,
                networkMonitor: deps.networkMonitor,
                sessionService: deps.sessionService,
                onNavigate: onNavigate
            )
        )
    }

    private func buildEditProfile() -> EditProfileView {
        EditProfileViewBuilder(deps: deps).build()
    }

    private func buildFollowing() -> FollowingView {
        FollowingView()
    }

    private func buildPostDetail(item: FeedPostItem) -> PostDetailView? {
        guard let userId = deps.sessionService.currentUser?.id else { return nil }

        return PostDetailView(
            item: item,
            currentUserId: userId,
            commentRepository: deps.commentRepository,
            profileRepository: deps.profileRepository,
            postRepository: deps.postRepository,
            networkMonitor: deps.networkMonitor
        )
    }

    @ViewBuilder
    func build(_ route: ProfileRoute, onNavigate: @escaping (ProfileRoute) -> Void) -> some View {
        switch route {
        case .profile:
            buildProfile(onNavigate: onNavigate)
        case .editProfile:
            buildEditProfile()
        case .following:
            buildFollowing()
        case .postDetail(let item):
            if let view = buildPostDetail(item: item) {
                view
            }
        }
    }
}
