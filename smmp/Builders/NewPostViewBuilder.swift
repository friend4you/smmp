//
//  NewPostViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct NewPostViewBuilder {
    let deps: AppDependencies

    func buildNewPost(onPostCreated: @escaping () -> Void) -> NewPostView {
        NewPostView(
            viewModel: CreatePostViewModel(
                postRepository: deps.postRepository,
                mediaService: deps.mediaService,
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
