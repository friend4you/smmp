//
//  SearchView.swift
//  smmp
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isOffline {
                offlineContent
            } else if viewModel.trimmedQuery.isEmpty {
                emptyContent
            } else if viewModel.showsMinLengthHint {
                minLengthContent
            } else if viewModel.isSearching && viewModel.results.isEmpty {
                searchSkeleton
            } else if viewModel.showsNoResults {
                noResultsContent
            } else {
                resultsList
            }
        }
        .searchable(text: $viewModel.query, prompt: Text(.searchPlaceholder))
        .navigationTitle(Text(.searchTitle))
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
    }

    private var resultsList: some View {
        List(viewModel.results) { result in
            SearchUserRowView(
                result: result,
                isFollowDisabled: !viewModel.canToggleFollow(for: result),
                isFollowInProgress: viewModel.followInProgressIds.contains(result.id),
                onRowTap: { viewModel.openProfile(user: result.user) },
                onFollowTap: {
                    Task { await viewModel.toggleFollow(for: result.id) }
                }
            )
        }
        .listStyle(.plain)
        .overlay(alignment: .top) {
            if viewModel.isSearching && !viewModel.results.isEmpty {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }

    private var searchSkeleton: some View {
        List(0..<4, id: \.self) { _ in
            SearchUserRowView(
                result: SearchUserResult(
                    user: User(id: "skeleton", displayName: "Loading User"),
                    isFollowing: false,
                    isSelf: false
                ),
                isFollowDisabled: true,
                isFollowInProgress: false,
                onRowTap: {},
                onFollowTap: {}
            )
            .redacted(reason: .placeholder)
            .allowsHitTesting(false)
        }
        .listStyle(.plain)
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Text(.searchTitle)
        } description: {
            Text(.searchEmpty)
        }
    }

    private var minLengthContent: some View {
        ContentUnavailableView {
            Text(.searchTitle)
        } description: {
            Text(.searchMinLength)
        }
    }

    private var noResultsContent: some View {
        ContentUnavailableView {
            Text(.searchNoResults)
        } description: {
            Text(.searchNoResultsHint)
        }
    }

    private var offlineContent: some View {
        ContentUnavailableView {
            Text(.searchTitle)
        } description: {
            Text(.searchRequiresConnection)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            OfflineBanner()
        }
    }
}

private struct SearchUserRowView: View {
    let result: SearchUserResult
    let isFollowDisabled: Bool
    let isFollowInProgress: Bool
    let onRowTap: () -> Void
    let onFollowTap: () -> Void

    private let avatarSize: CGFloat = 44

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onRowTap) {
                HStack(spacing: 12) {
                    userAvatar

                    Text(result.user.displayName ?? String(localized: .commonUser))
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            if !result.isSelf {
                Button(action: onFollowTap) {
                    Group {
                        if isFollowInProgress {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(result.isFollowing ? .followUnfollow : .followFollow)
                        }
                    }
                    .frame(minWidth: 88)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isFollowDisabled || isFollowInProgress)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var userAvatar: some View {
        if let photoURL = result.user.photoURL,
           !photoURL.isEmpty,
           let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    avatarPlaceholder
                }
            }
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: avatarSize))
            .foregroundStyle(.secondary)
    }
}

#Preview {
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
        SearchView(
            viewModel: SearchViewModel(
                profileRepository: profileRepository,
                followRepository: FollowRepository(profileRepository: profileRepository),
                sessionService: SessionService(),
                networkMonitor: network,
                hapticService: HapticService()
            )
        )
    }
}
