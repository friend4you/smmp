//
//  FeedViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct FeedViewBuilder {
    let deps: AppDependenciesProviding

    private func buildFeed(onNavigate: @escaping (FeedRoute) -> Void) -> FeedView {
        FeedView(
            viewModel: FeedViewModel(
                postRepository: deps.postRepository,
                profileRepository: deps.profileRepository,
                networkMonitor: deps.networkMonitor,
                sessionService: deps.sessionService,
                onNavigate: onNavigate
            )
        )
    }
    
    private func buildPostDetails(post: FeedPostItem, onNavigate: @escaping (FeedRoute) -> Void) -> PostDetailView? {
        guard let userId = deps.sessionService.currentUser?.id else { return nil }
        
        return PostDetailView(
            item: post,
            currentUserId: userId,
            commentRepository: deps.commentRepository,
            profileRepository: deps.profileRepository,
            postRepository: deps.postRepository,
            networkMonitor: deps.networkMonitor
        )
    }

    @ViewBuilder
    func build(_ route: FeedRoute, onNavigate: @escaping (FeedRoute) -> Void) -> some View {
        switch route {
        case .feed:
            buildFeed(onNavigate: onNavigate)
        case .postDetail(let item):
            buildPostDetails(post: item, onNavigate: onNavigate)
        }
    }
}
