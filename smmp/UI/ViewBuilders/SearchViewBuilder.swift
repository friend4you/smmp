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
        SearchView(
            viewModel: SearchViewModel(
                profileRepository: deps.profileRepository,
                followRepository: deps.followRepository,
                sessionService: deps.sessionService,
                networkMonitor: deps.networkMonitor,
                hapticService: deps.hapticService,
                onNavigate: onNavigate
            )
        )
    }

    private func buildUserProfile(
        userId: String,
        stub: User?,
        onNavigate: @escaping (SearchRoute) -> Void
    ) -> UserProfileView {
        userProfileBuilder.build(
            userId: userId,
            userStub: stub,
            onPostDetail: { onNavigate(.postDetail($0)) },
            onEditProfile: { onNavigate(.editProfile) },
            onFollowing: { onNavigate(.following) }
        )
    }

    private func buildPostDetail(
        item: FeedPostItem,
        onNavigate: @escaping (SearchRoute) -> Void
    ) -> PostDetailView? {
        guard let userId = deps.sessionService.currentUser?.id else { return nil }

        return PostDetailView(
            item: item,
            currentUserId: userId,
            commentRepository: deps.commentRepository,
            profileRepository: deps.profileRepository,
            postRepository: deps.postRepository,
            networkMonitor: deps.networkMonitor,
            hapticService: deps.hapticService,
            onAuthorTap: { user in
                onNavigate(.userProfile(userId: user.id, stub: user))
            }
        )
    }

    private func buildEditProfile() -> EditProfileView {
        EditProfileViewBuilder(deps: deps).build()
    }

    private func buildFollowing() -> FollowingView {
        FollowingViewBuilder(deps: deps).build()
    }

    @ViewBuilder
    func build(_ route: SearchRoute, onNavigate: @escaping (SearchRoute) -> Void) -> some View {
        switch route {
        case .search:
            buildSearch(onNavigate: onNavigate)
        case .userProfile(let userId, let stub):
            buildUserProfile(userId: userId, stub: stub, onNavigate: onNavigate)
        case .postDetail(let item):
            if let view = buildPostDetail(item: item, onNavigate: onNavigate) {
                view
            }
        case .editProfile:
            buildEditProfile()
        case .following:
            buildFollowing()
        }
    }
}
