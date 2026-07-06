//
//  FollowingViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct FollowingViewBuilder {
    let deps: AppDependenciesProviding

    func build() -> FollowingView {
        FollowingView(
            viewModel: FollowingViewModel(
                followRepository: deps.followRepository,
                profileRepository: deps.profileRepository,
                sessionService: deps.sessionService,
                networkMonitor: deps.networkMonitor
            )
        )
    }
}
