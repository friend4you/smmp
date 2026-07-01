//
//  FeedViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct FeedViewBuilder {
    let deps: AppDependencies
    let sessionService: SessionService

    func buildFeed(onNavigate: @escaping (FeedRoute) -> Void) -> FeedView {
        FeedView(
            viewModel: FeedViewModel(
                postRepository: deps.postRepository,
                profileRepository: deps.profileRepository,
                networkMonitor: deps.networkMonitor,
                onNavigate: onNavigate
            )
        )
    }

    @ViewBuilder
    func build(_ route: FeedRoute, onNavigate: @escaping (FeedRoute) -> Void) -> some View {
        switch route {
        case .postDetail(let item):
            if let userId = sessionService.currentUser?.id {
                PostDetailView(
                    item: item,
                    currentUserId: userId,
                    commentRepository: deps.commentRepository,
                    profileRepository: deps.profileRepository,
                    postRepository: deps.postRepository,
                    networkMonitor: deps.networkMonitor
                )
            }
        }
    }
}
