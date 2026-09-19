//
//  ProfileView.swift
//  smmp
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
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
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    viewModel.openPrivacyPolicy()
                } label: {
                    Label(.legalPrivacyPolicy, systemImage: "hand.raised")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    viewModel.openTermsOfUse()
                } label: {
                    Label(.legalTermsOfUse, systemImage: "doc.text")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    if let url = viewModel.supportMailtoURL {
                        openURL(url)
                    }
                } label: {
                    Label(.legalContact, systemImage: "envelope")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button(role: .destructive) {
                    viewModel.requestDeleteAccount()
                } label: {
                    Label(.accountDeleteAction, systemImage: "trash")
                }
                .disabled(!viewModel.canDeleteAccount)
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
        .confirmationDialog(
            Text(.accountDeleteConfirmTitle),
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                viewModel.confirmDeleteAccount()
            } label: {
                Text(.accountDeleteConfirmAction)
            }
            Button(role: .cancel) {
                viewModel.cancelDeleteAccount()
            } label: {
                Text(.commonCancel)
            }
        } message: {
            Text(.accountDeleteConfirmMessage)
        }
        .alert(
            Text(.accountDeletePasswordTitle),
            isPresented: $viewModel.showDeletePasswordPrompt
        ) {
            SecureField(
                String(localized: .accountDeletePasswordPlaceholder),
                text: $viewModel.deletePassword
            )
            Button(role: .destructive) {
                Task { await viewModel.performDeleteAccount() }
            } label: {
                Text(.accountDeleteConfirmAction)
            }
            Button(role: .cancel) {
                viewModel.cancelDeleteAccount()
            } label: {
                Text(.commonCancel)
            }
        } message: {
            Text(.accountDeletePasswordMessage)
        }
        .sheet(item: $viewModel.presentedLegalURL) { item in
            SafariView(url: item.url)
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
                hapticService: HapticService(),
                authReauthenticator: AuthService(),
                accountDeletionService: AccountDeletionService(
                    postRepository: PostRepository(
                        networkMonitor: network,
                        localRepository: localRepository,
                        mediaService: media
                    ),
                    commentRepository: CommentRepository(
                        networkMonitor: network,
                        localRepository: localRepository,
                        mediaService: media
                    ),
                    followRepository: FollowRepository(profileRepository: ProfileRepository(
                        networkMonitor: network,
                        localRepository: localRepository,
                        mediaService: media,
                        authProfileUpdater: AuthService()
                    )),
                    blockRepository: BlockRepository(),
                    mediaService: media,
                    userDocuments: FirestoreUserDocumentRepository(),
                    accountDeleter: AuthService(),
                    authRepository: AuthRepository(authService: AuthService())
                )
            )
        )
    }
}
