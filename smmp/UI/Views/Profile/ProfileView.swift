//
//  ProfileView.swift
//  smmp
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
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
                        isOwnProfile: true,
                        onFollowingTapped: viewModel.followingTapped
                    )

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
        .navigationTitle(Text(.tabProfile))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.editProfileTapped()
                } label: {
                    Text(.profileEdit)
                }
                .disabled(!viewModel.canEditProfile)
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    Task {
                        await viewModel.logout()
                    }
                } label: {
                    Label(.profileLogout, systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
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

    private var profileSkeleton: some View {
        VStack(spacing: 16) {
            ProfileHeaderView(
                user: User(id: "skeleton", displayName: "Loading Profile"),
                isOwnProfile: true
            )
            .redacted(reason: .placeholder)

            PostListSkeleton(count: 2)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    let network = NetworkMonitor()
    let localRepository = LocalRepository(persistence: PersistenceController.shared)
    let media = MediaService()

    NavigationStack {
        ProfileView(
            viewModel: ProfileViewModel(
                authRepository: AuthRepository(authService: AuthService()),
                profileRepository: ProfileRepository(
                    networkMonitor: network,
                    localRepository: localRepository,
                    mediaService: media,
                    authProfileUpdater: AuthService()
                ),
                postRepository: PostRepository(
                    networkMonitor: network,
                    localRepository: localRepository,
                    mediaService: media
                ),
                localRepository: localRepository,
                networkMonitor: network,
                sessionService: SessionService(),
                hapticService: HapticService()
            )
        )
    }
}
