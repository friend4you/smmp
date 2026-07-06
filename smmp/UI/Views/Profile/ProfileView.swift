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
                    offlineBanner
                }

                if viewModel.isLoading && viewModel.user == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                } else if let user = viewModel.user {
                    ProfileHeaderView(
                        user: user,
                        isOwnProfile: true,
                        onFollowingTapped: viewModel.followingTapped
                    )

                    ProfilePostsListSection(
                        items: viewModel.items,
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
    }

    private var offlineBanner: some View {
        Text(.profileOfflineBanner)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let network = NetworkMonitor()
    let localRepository = LocalRepository(persistence: PersistenceController.shared)
    let media = MediaService()

    return NavigationStack {
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
                sessionService: SessionService()
            )
        )
    }
}
