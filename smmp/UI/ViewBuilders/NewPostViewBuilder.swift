//
//  NewPostViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct NewPostViewBuilder {
    let deps: AppDependenciesProviding

    private func buildNewPost(onPostCreated: @escaping () -> Void) -> NewPostView {
        NewPostView(
            viewModel: CreatePostViewModel(
                postRepository: deps.postRepository,
                followRepository: deps.followRepository,
                mediaService: deps.mediaService,
                sessionService: deps.sessionService,
                networkMonitor: deps.networkMonitor,
                onPostCreated: onPostCreated
            )
        )
    }

    @ViewBuilder
    func build(_ route: NewPostRoute, onPostCreated: @escaping () -> Void) -> some View {
        switch route {
        case .newPost:
            buildNewPost(onPostCreated: onPostCreated)
        }
    }
}
