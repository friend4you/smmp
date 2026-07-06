//
//  FeedViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct FeedViewBuilder {
    let deps: AppDependenciesProviding

    private var userProfileBuilder: UserProfileViewBuilder {
        UserProfileViewBuilder(deps: deps)
    }

    private func buildFeed(onNavigate: @escaping (FeedRoute) -> Void) -> FeedView {
        FeedView(
            viewModel: FeedViewModel(
                postRepository: deps.postRepository,
                profileRepository: deps.profileRepository,
                followRepository: deps.followRepository,
                networkMonitor: deps.networkMonitor,
                sessionService: deps.sessionService,
                onNavigate: onNavigate
            )
        )
    }

    private func buildUserProfile(
        userId: String,
        onNavigate: @escaping (FeedRoute) -> Void
    ) -> UserProfileView {
        userProfileBuilder.build(
            userId: userId,
            onPostDetail: { onNavigate(.postDetail($0)) },
            onEditProfile: { onNavigate(.editProfile) },
            onFollowing: { onNavigate(.following) }
        )
    }

    private func buildPostDetails(
        post: FeedPostItem,
        onNavigate: @escaping (FeedRoute) -> Void
    ) -> PostDetailView? {
        guard let userId = deps.sessionService.currentUser?.id else { return nil }

        return PostDetailView(
            item: post,
            currentUserId: userId,
            commentRepository: deps.commentRepository,
            profileRepository: deps.profileRepository,
            postRepository: deps.postRepository,
            networkMonitor: deps.networkMonitor,
            onAuthorTap: { onNavigate(.userProfile(userId: $0)) }
        )
    }

    private func buildEditProfile() -> EditProfileView {
        EditProfileViewBuilder(deps: deps).build()
    }

    private func buildFollowing() -> FollowingView {
        FollowingViewBuilder(deps: deps).build()
    }

    @ViewBuilder
    func build(_ route: FeedRoute, onNavigate: @escaping (FeedRoute) -> Void) -> some View {
        switch route {
        case .feed:
            buildFeed(onNavigate: onNavigate)
        case .userProfile(let userId):
            buildUserProfile(userId: userId, onNavigate: onNavigate)
        case .postDetail(let item):
            if let view = buildPostDetails(post: item, onNavigate: onNavigate) {
                view
            }
        case .editProfile:
            buildEditProfile()
        case .following:
            buildFollowing()
        }
    }
}
