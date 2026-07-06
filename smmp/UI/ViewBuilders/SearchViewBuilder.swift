//
//  SearchViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct SearchViewBuilder {
    let deps: AppDependenciesProviding

    private var userProfileBuilder: UserProfileViewBuilder {
        UserProfileViewBuilder(deps: deps)
    }

    private func buildSearch(onNavigate: @escaping (SearchRoute) -> Void) -> SearchView {
        SearchView()
    }

    private func buildUserProfile(
        userId: String,
        onNavigate: @escaping (SearchRoute) -> Void
    ) -> UserProfileView {
        userProfileBuilder.build(
            userId: userId,
            onPostDetail: { onNavigate(.postDetail($0)) },
            onEditProfile: { onNavigate(.editProfile) },
            onFollowing: { onNavigate(.following) }
        )
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

    private func buildEditProfile() -> EditProfileView {
        EditProfileView()
    }

    private func buildFollowing() -> FollowingView {
        FollowingView()
    }

    @ViewBuilder
    func build(_ route: SearchRoute, onNavigate: @escaping (SearchRoute) -> Void) -> some View {
        switch route {
        case .search:
            buildSearch(onNavigate: onNavigate)
        case .userProfile(let userId):
            buildUserProfile(userId: userId, onNavigate: onNavigate)
        case .postDetail(let item):
            if let view = buildPostDetail(item: item) {
                view
            }
        case .editProfile:
            buildEditProfile()
        case .following:
            buildFollowing()
        }
    }
}
