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
        userStub: User? = nil,
        onPostDetail: @escaping (FeedPostItem) -> Void,
        onEditProfile: @escaping () -> Void,
        onFollowing: @escaping () -> Void
    ) -> UserProfileView {
        UserProfileView(
            viewModel: UserProfileViewModel(
                userId: userId,
                userStub: userStub,
                profileRepository: deps.profileRepository,
                postRepository: deps.postRepository,
                followRepository: deps.followRepository,
                localRepository: deps.localRepository,
                networkMonitor: deps.networkMonitor,
                sessionService: deps.sessionService,
                hapticService: deps.hapticService,
                onPostDetail: onPostDetail,
                onEditProfile: onEditProfile,
                onFollowing: onFollowing
            )
        )
    }
}
