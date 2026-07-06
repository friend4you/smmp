//
//  UserProfileViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct UserProfileViewBuilder {
    let deps: AppDependenciesProviding

    func build(
        userId: String,
        onPostDetail: @escaping (FeedPostItem) -> Void,
        onEditProfile: @escaping () -> Void,
        onFollowing: @escaping () -> Void
    ) -> UserProfileView {
        UserProfileView(
            viewModel: UserProfileViewModel(
                userId: userId,
                profileRepository: deps.profileRepository,
                postRepository: deps.postRepository,
                followRepository: deps.followRepository,
                localRepository: deps.localRepository,
                networkMonitor: deps.networkMonitor,
                sessionService: deps.sessionService,
                onPostDetail: onPostDetail,
                onEditProfile: onEditProfile,
                onFollowing: onFollowing
            )
        )
    }
}
