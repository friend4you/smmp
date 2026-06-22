//
//  FeedView.swift
//  smmp
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var sessionService: SessionService
    @StateObject private var viewModel: FeedViewModel

    init(
        postRepository: PostRepositoryProtocol,
        profileRepository: ProfileRepositoryProtocol,
        networkMonitor: NetworkMonitor
    ) {
        _viewModel = StateObject(
            wrappedValue: FeedViewModel(
                postRepository: postRepository,
                profileRepository: profileRepository,
                networkMonitor: networkMonitor
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                feedList

                if viewModel.showNewPostsBanner {
                    newPostsBanner
                }
            }
            .navigationTitle(Text(.feedTitle))
            .alert(
                Text(.commonErrorTitle),
                isPresented: $viewModel.showError,
                presenting: viewModel.errorMessage
            ) { _ in
                Button(String(localized: .commonOk)) {
                    viewModel.showError = false
                }
            } message: { message in
                Text(message)
            }
            .task(id: sessionService.currentUser?.id) {
                guard let userId = sessionService.currentUser?.id else { return }
                viewModel.start(userId: userId)
            }
        }
    }

    @ViewBuilder
    private var feedList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.isOffline {
                        offlineBanner
                    }

                    if viewModel.items.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.items) { item in
                            NavigationLink(value: item) {
                                PostCardView(item: item) {
                                    Task { await viewModel.toggleLike(for: item) }
                                }
                            }
                            .buttonStyle(.plain)
                            .id(item.id)
                            .task {
                                await viewModel.loadMoreIfNeeded(currentItem: item)
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y <= 4
            } action: { _, isAtTop in
                viewModel.updateScrollAtTop(isAtTop)
            }
            .onChange(of: viewModel.scrollToTopRequest) { _, _ in
                guard let firstId = viewModel.items.first?.id else { return }
                withAnimation {
                    proxy.scrollTo(firstId, anchor: .top)
                }
            }
            .navigationDestination(for: FeedPostItem.self) { item in
                PostDetailView(item: item)
            }
        }
    }

    private var offlineBanner: some View {
        Text(.feedOfflineBanner)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            label: { Text(.feedEmptyTitle) },
            description: { Text(.feedEmptyDescription) }
        )
        .padding(.top, 48)
    }

    private var newPostsBanner: some View {
        Button {
            viewModel.revealNewPosts()
        } label: {
            Text(.feedNewPostsBanner)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .clipShape(Capsule())
                .shadow(radius: 4)
        }
        .padding(.top, 8)
        .zIndex(1)
    }
}

#Preview {
    FeedView(
        postRepository: PostRepository(
            networkMonitor: NetworkMonitor(),
            localRepository: LocalRepository(persistence: PersistenceController.shared),
            persistence: PersistenceController.shared,
            mediaService: MediaService()
        ),
        profileRepository: ProfileRepository(
            networkMonitor: NetworkMonitor(),
            localRepository: LocalRepository(persistence: PersistenceController.shared),
            persistence: PersistenceController.shared,
            mediaService: MediaService()
        ),
        networkMonitor: NetworkMonitor()
    )
    .environmentObject(SessionService())
}
