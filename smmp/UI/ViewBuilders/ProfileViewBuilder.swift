//
//  ProfileViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct ProfileViewBuilder {
    let deps: AppDependenciesProviding

    private var userProfileBuilder: UserProfileViewBuilder {
        UserProfileViewBuilder(deps: deps)
    }

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
        FollowingViewBuilder(deps: deps).build()
    }

    private func buildPostDetail(
        item: FeedPostItem,
        onNavigate: @escaping (ProfileRoute) -> Void
    ) -> PostDetailView? {
        guard let userId = deps.sessionService.currentUser?.id else { return nil }

        return PostDetailView(
            item: item,
            currentUserId: userId,
            commentRepository: deps.commentRepository,
            profileRepository: deps.profileRepository,
            postRepository: deps.postRepository,
            networkMonitor: deps.networkMonitor,
            onAuthorTap: { onNavigate(.userProfile(userId: $0)) }
        )
    }

    private func buildUserProfile(
        userId: String,
        onNavigate: @escaping (ProfileRoute) -> Void
    ) -> UserProfileView {
        userProfileBuilder.build(
            userId: userId,
            onPostDetail: { onNavigate(.postDetail($0)) },
            onEditProfile: { onNavigate(.editProfile) },
            onFollowing: { onNavigate(.following) }
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
        case .userProfile(let userId):
            buildUserProfile(userId: userId, onNavigate: onNavigate)
        case .postDetail(let item):
            if let view = buildPostDetail(item: item, onNavigate: onNavigate) {
                view
            }
        }
    }
}
