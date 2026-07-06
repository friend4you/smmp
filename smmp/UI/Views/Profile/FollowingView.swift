//
//  FollowingView.swift
//  smmp
//

import SwiftUI

struct FollowingView: View {
    @StateObject private var viewModel: FollowingViewModel

    init(viewModel: FollowingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.rows.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.rows.isEmpty {
                ContentUnavailableView {
                    Text(.followListTitle)
                } description: {
                    Text(emptyDescription)
                }
            } else {
                List(viewModel.rows) { row in
                    FollowingUserRowView(
                        row: row,
                        isUnfollowDisabled: !viewModel.canUnfollow(userId: row.id),
                        isUnfollowInProgress: viewModel.unfollowInProgressIds.contains(row.id),
                        onUnfollow: {
                            Task { await viewModel.unfollow(userId: row.id) }
                        }
                    )
                }
                .listStyle(.plain)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if viewModel.isOffline {
                offlineBanner
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle(Text(.followListTitle))
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
    }

    private var emptyDescription: LocalizedStringResource {
        viewModel.isOffline ? .followListOffline : .followListPlaceholder
    }

    private var offlineBanner: some View {
        Text(.profileOfflineBanner)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange)
    }
}

private struct FollowingUserRowView: View {
    let row: FollowingUserRow
    let isUnfollowDisabled: Bool
    let isUnfollowInProgress: Bool
    let onUnfollow: () -> Void

    private let avatarSize: CGFloat = 44

    var body: some View {
        HStack(spacing: 12) {
            userAvatar

            Text(row.user.displayName ?? String(localized: .commonUser))
                .font(.body.weight(.medium))
                .lineLimit(1)

            Spacer(minLength: 8)

            Button(action: onUnfollow) {
                Group {
                    if isUnfollowInProgress {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(.followUnfollow)
                    }
                }
                .frame(minWidth: 88)
            }
            .buttonStyle(.bordered)
            .disabled(isUnfollowDisabled || isUnfollowInProgress)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var userAvatar: some View {
        if let photoURL = row.user.photoURL,
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

    return NavigationStack {
        FollowingView(
            viewModel: FollowingViewModel(
                followRepository: FollowRepository(profileRepository: profileRepository),
                profileRepository: profileRepository,
                sessionService: SessionService(),
                networkMonitor: network
            )
        )
    }
}
