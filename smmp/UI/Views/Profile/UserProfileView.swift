//
//  UserProfileView.swift
//  smmp
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel

    init(viewModel: UserProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isOffline {
                    OfflineBanner()
                }

                if !viewModel.hasCompletedInitialLoad && viewModel.user == nil {
                    profileSkeleton
                } else if let user = viewModel.user {
                    ProfileHeaderView(
                        user: user,
                        isOwnProfile: viewModel.isOwnProfile,
                        onFollowingTapped: viewModel.isOwnProfile
                            ? { viewModel.followingTapped() }
                            : nil
                    )

                    actionButton

                    ProfilePostsListSection(
                        items: viewModel.items,
                        isLoading: !viewModel.hasCompletedInitialLoad,
                        isLikeDisabled: viewModel.isOffline,
                        onPostTapped: viewModel.showPostDetail,
                        onLikeTapped: { item in
                            Task { await viewModel.toggleLike(for: item) }
                        }
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle(viewModel.user?.displayName ?? String(localized: .commonUser))
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            Text(.commonErrorTitle),
            isPresented: $viewModel.showError,
            presenting: viewModel.errorMessage
        ) { _ in
            Button { viewModel.showError = false } label: {
                Text(.commonOk)
            }
        } message: { message in
            Text(message)
        }
        .task {
            await viewModel.load()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if viewModel.showsFollowButton {
            Button {
                Task { await viewModel.toggleFollow() }
            } label: {
                Group {
                    if viewModel.isFollowActionInProgress {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(viewModel.isFollowing ? .followUnfollow : .followFollow)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canToggleFollow)
        } else if viewModel.showsEditButton {
            Button {
                viewModel.editProfileTapped()
            } label: {
                Text(.profileEdit)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canEditProfile)
        }
    }

    private var profileSkeleton: some View {
        VStack(spacing: 16) {
            ProfileHeaderView(
                user: User(id: "skeleton", displayName: "Loading Profile"),
                isOwnProfile: false
            )
            .redacted(reason: .placeholder)

            PostListSkeleton(count: 2)
        }
        .allowsHitTesting(false)
    }
}

#Preview("Other user") {
    let network = NetworkMonitor()
    let localRepository = LocalRepository(persistence: PersistenceController.shared)
    let media = MediaService()
    let profileRepository = ProfileRepository(
        networkMonitor: network,
        localRepository: localRepository,
        mediaService: media,
        authProfileUpdater: AuthService()
    )

    NavigationStack {
        UserProfileView(
            viewModel: UserProfileViewModel(
                userId: "user-2",
                profileRepository: profileRepository,
                postRepository: PostRepository(
                    networkMonitor: network,
                    localRepository: localRepository,
                    mediaService: media
                ),
                followRepository: FollowRepository(profileRepository: profileRepository),
                localRepository: localRepository,
                networkMonitor: network,
                sessionService: SessionService(),
                hapticService: HapticService(),
                onPostDetail: { _ in },
                onEditProfile: {},
                onFollowing: {}
            )
        )
    }
}
