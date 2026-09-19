//
//  EditProfileViewBuilder.swift
//  smmp
//

import SwiftUI

@MainActor
struct EditProfileViewBuilder {
    let deps: AppDependenciesProviding

    func build(onSaved: @escaping () -> Void = {}) -> EditProfileView {
        EditProfileView(
            viewModel: EditProfileViewModel(
                profileRepository: deps.profileRepository,
                mediaService: deps.mediaService,
                sessionService: deps.sessionService,
                networkMonitor: deps.networkMonitor,
                contentFilter: deps.contentFilter,
                onSaved: onSaved
            )
        )
    }
}
